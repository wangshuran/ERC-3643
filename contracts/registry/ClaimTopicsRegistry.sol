pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IClaimTopicsRegistry.sol";

// @title ERC-3643 - 声明主题注册表
// @dev 管理声明主题的注册表。
contract ClaimTopicsRegistry is IClaimTopicsRegistry, Ownable {
    // @dev 存储所有所需声明主题的数组。
    uint256[] private _claimTopics;

    // @notice 将一个声明主题添加到注册表中。
    // @dev 仅合约所有者可以调用。
    // 触发 ClaimTopicAdded 事件。
    // @param _claimTopic 要添加的声明主题。
    function addClaimTopic(uint256 _claimTopic) external onlyOwner {
        require(_isClaimTopicUnique(_claimTopic), unicode"ERC-3643: 主题已存在");

        _claimTopics.push(_claimTopic);
        emit ClaimTopicAdded(_claimTopic);
    }

    // @notice 从注册表中移除一个声明主题。
    // @dev 仅合约所有者可以调用。
    // 触发 ClaimTopicRemoved 事件。
    // @param _claimTopic 要移除的声明主题。
    function removeClaimTopic(uint256 _claimTopic) external onlyOwner {
        uint256 length = _claimTopics.length;
        for (uint256 i = 0; i < length; i++) {
            if (_claimTopics[i] == _claimTopic) {
                _claimTopics[i] = _claimTopics[length - 1];
                _claimTopics.pop();
                emit ClaimTopicRemoved(_claimTopic);
                break;
            }
        }
    }

    // @notice 获取注册表中的所有声明主题。
    // @return uint256[] 声明主题数组。
    function getClaimTopics() external view returns (uint256[] memory) {
        return _claimTopics;
    }

    // @notice 检查声明主题在注册表中是否唯一。
    // @dev 私有函数，用于检查声明主题的唯一性。
    // @param claimTopic 要检查的声明主题。
    // @return bool 如果声明主题唯一则返回 true，否则返回 false。
    function _isClaimTopicUnique(
        uint256 claimTopic
    ) private view returns (bool) {
        uint256[] memory claimTopics = _claimTopics;
        uint256 length = _claimTopics.length;
        for (uint256 i = 0; i < length; ) {
            if (claimTopics[i] == claimTopic) {
                return false;
            }
            unchecked {
                ++i;
            }
        }
        return true;
    }
}