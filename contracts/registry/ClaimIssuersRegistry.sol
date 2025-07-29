pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IClaimIssuersRegistry.sol";

// @title ERC-3643 - 声明发行者注册表
// @dev 此合约维护一个声明发行者及其关联的声明主题的注册表，用于ERC-3643标准。
contract ClaimIssuersRegistry is IClaimIssuersRegistry, Ownable {
    // @dev 存储所有声明发行者的数组。
    IClaimIssuer[] private _claimIssuers;

    // @dev 映射声明发行者地址与其对应的声明主题。
    mapping(IClaimIssuer => uint256[]) private _claimIssuerClaimTopics;

    // @dev 映射声明主题与允许发出该主题的声明发行者。
    mapping(uint256 => IClaimIssuer[]) private _claimTopicToClaimIssuers;

    // @notice 将声明发行者添加到声明发行者注册表中。
    // @param _claimIssuer 声明发行者的地址。
    // @param _claimTopics 与声明发行者关联的声明主题数组。
    // 要求:
    // - 调用者必须是合约的所有者。
    // - 声明发行者地址不能为零地址。
    // - 声明发行者不能已经在注册表中存在。
    // - 声明主题数组不能为空。
    // - 建议一次性添加合理的声明发行者数量。
    // 触发 ClaimIssuerAdded 事件。
    function addClaimIssuer(
        IClaimIssuer _claimIssuer,
        uint256[] calldata _claimTopics
    ) external onlyOwner {
        require(
            address(_claimIssuer) != address(0),
            unicode"ERC-3643: 无效的零地址"
        );
        require(
            _claimIssuerClaimTopics[_claimIssuer].length == 0,
            unicode"ERC-3643: 发行者已存在"
        );
        uint length = _claimTopics.length;
        require(length != 0, unicode"ERC-3643: 空的声明主题");

        _claimIssuers.push(_claimIssuer);
        _claimIssuerClaimTopics[_claimIssuer] = _claimTopics;

        for (uint256 i = 0; i < length; ) {
            _claimTopicToClaimIssuers[_claimTopics[i]].push(_claimIssuer);
            unchecked {
                ++i;
            }
        }

        emit ClaimIssuerAdded(_claimIssuer, _claimTopics);
    }

    // @notice 从声明发行者注册表中移除声明发行者。
    // @param _claimIssuer 要移除的声明发行者的地址。
    // 要求:
    // - 调用者必须是合约的所有者。
    // - 声明发行者必须存在于注册表中。
    // 触发 ClaimIssuerRemoved 事件。
    function removeClaimIssuer(IClaimIssuer _claimIssuer) external onlyOwner {
        uint claimIssuerTopicsLength = _claimIssuerClaimTopics[_claimIssuer]
            .length;
        require(claimIssuerTopicsLength != 0, unicode"ERC-3643: 不是声明发行者");
        uint256 claimIssuerlength = _claimIssuers.length;
        for (uint256 i = 0; i < claimIssuerlength; ) {
            if (_claimIssuers[i] == _claimIssuer) {
                _claimIssuers[i] = _claimIssuers[claimIssuerlength - 1];
                _claimIssuers.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }

        _removeClaimIssuerFromAllClaimTopics(
            _claimIssuer,
            claimIssuerTopicsLength
        );

        delete _claimIssuerClaimTopics[_claimIssuer];
        emit ClaimIssuerRemoved(_claimIssuer);
    }

    // @notice 更新与声明发行者关联的声明主题。
    // @param _claimIssuer 声明发行者的地址。
    // @param _claimTopics 要与声明发行者关联的声明主题数组。
    // 要求:
    // - 调用者必须是合约的所有者。
    // - 声明发行者必须存在于注册表中。
    // - 声明主题数组不能为空。
    // 触发 ClaimTopicsUpdated 事件。
    function updateIssuerClaimTopics(
        IClaimIssuer _claimIssuer,
        uint256[] calldata _claimTopics
    ) external onlyOwner {
        require(_claimTopics.length != 0, unicode"ERC-3643: 没有声明主题");
        uint claimIssuerTopicsLength = _claimIssuerClaimTopics[_claimIssuer]
            .length;
        require(claimIssuerTopicsLength != 0, unicode"ERC-3643: 不是声明发行者");

        _updateIssuerAcrossAllTopics(_claimIssuer);

        _claimIssuerClaimTopics[_claimIssuer] = _claimTopics;

        emit ClaimTopicsUpdated(_claimIssuer, _claimTopics);
    }

    // @notice 返回注册表中所有声明发行者的数组。
    // @return 内存中的声明发行者数组。
    function getClaimIssuers() external view returns (IClaimIssuer[] memory) {
        return _claimIssuers;
    }

    // @notice 返回与特定声明主题关联的所有声明发行者的数组。
    // @param claimTopic 要查找关联声明发行者的声明主题。
    // @return 内存中的声明发行者数组。
    function getClaimIssuersForClaimTopic(
        uint256 claimTopic
    ) external view returns (IClaimIssuer[] memory) {
        return _claimTopicToClaimIssuers[claimTopic];
    }

    // @notice 检查地址是否是注册表中的声明发行者。
    // @param _issuer 要检查的地址。
    // @return 如果地址是声明发行者，则返回 true，否则返回 false。
    function isClaimIssuer(IClaimIssuer _issuer) external view returns (bool) {
        return _isClaimIssuer(_issuer);
    }

    // @notice 返回与特定声明发行者关联的所有声明主题的数组。
    // @param _claimIssuer 要查找关联声明主题的声明发行者。
    // @return 内存中的声明主题数组。
    function getClaimIssuerClaimTopics(
        IClaimIssuer _claimIssuer
    ) external view returns (uint256[] memory) {
        require(_isClaimIssuer(_claimIssuer), unicode"ERC-3643: 发行者不存在");
        return _claimIssuerClaimTopics[_claimIssuer];
    }

    // @notice 检查声明发行者是否具有特定的声明主题。
    // @dev 此函数检查特定的声明主题是否与声明发行者相关联。
    // @param _issuer 要检查的声明发行者。
    // @param _claimTopic 要检查的声明主题。
    // @return bool 如果声明发行者具有该声明主题，则返回 true，否则返回 false。
    function hasClaimTopic(
        IClaimIssuer _issuer,
        uint256 _claimTopic
    ) external view returns (bool) {
        uint256 length = _claimIssuerClaimTopics[_issuer].length;
        uint256[] memory claimTopics = _claimIssuerClaimTopics[_issuer];
        for (uint256 i = 0; i < length; ) {
            if (claimTopics[i] == _claimTopic) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    // @dev 从所有关联的声明主题中移除声明发行者。
    // @param claimIssuer 要移除的声明发行者。
    // @param length 与声明发行者关联的声明主题的数量。
    function _removeClaimIssuerFromAllClaimTopics(
        IClaimIssuer claimIssuer,
        uint length
    ) private {
        for (uint256 i = 0; i < length; ) {
            uint256 claimTopic = _claimIssuerClaimTopics[claimIssuer][i];

            _removeIssuerFromTopic(claimIssuer, claimTopic);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 更新声明发行者在所有关联的声明主题中的信息。
    //      函数会从每个主题中移除声明发行者，然后重新添加它。
    // @param claimIssuer 要更新的声明发行者。
    function _updateIssuerAcrossAllTopics(IClaimIssuer claimIssuer) private {
        uint256[] memory claimTopics = _claimIssuerClaimTopics[claimIssuer];
        uint length = claimTopics.length;

        for (uint256 i = 0; i < length; ) {
            uint256 claimTopic = claimTopics[i];

            _removeIssuerFromTopic(claimIssuer, claimTopic);
            _claimTopicToClaimIssuers[claimTopics[i]].push(claimIssuer);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 从特定的声明主题中移除声明发行者。
    //      函数会识别并替换列表中的声明发行者，然后移除最后一个元素，从而有效地从列表中移除发行人。
    // @param claimIssuer 要移除的声明发行者。
    // @param claimTopic 要从中移除发行者的声明主题标识符。
    function _removeIssuerFromTopic(
        IClaimIssuer claimIssuer,
        uint claimTopic
    ) private {
        IClaimIssuer[] memory claimIssuers = _claimTopicToClaimIssuers[
            claimTopic
        ];
        uint length = claimIssuers.length;

        for (uint j = 0; j < length; ) {
            if (claimIssuers[j] == claimIssuer) {
                _claimTopicToClaimIssuers[claimTopic][j] = claimIssuers[
                    length - 1
                ];
                _claimTopicToClaimIssuers[claimTopic].pop();
                break;
            }
            unchecked {
                ++j;
            }
        }
    }

    // @dev 检查地址是否是声明发行者。
    // @param _issuer 要检查的地址。
    // @return bool 如果地址是声明发行者，则返回 true，否则返回 false。
    function _isClaimIssuer(IClaimIssuer _issuer) private view returns (bool) {
        return (_claimIssuerClaimTopics[_issuer].length != 0);
    }
}