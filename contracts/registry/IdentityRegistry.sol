// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "./interface/IClaimTopicsRegistry.sol";
import "./interface/IClaimIssuersRegistry.sol";
import "./interface/IIdentityRegistry.sol";
import "./interface/IIdentityRegistryStorage.sol";

// @title ERC-3643 - 身份注册表
// @dev 此合约用于管理符合 ERC-3643 标准的身份。
// 它允许注册、更新和删除与用户地址相关联的身份。
// 它还支持对声明主题和声明发行者的管理。
contract IdentityRegistry is IIdentityRegistry, AccessControl {
    // @notice ClaimTopicsRegistry 合约的地址。
    IClaimTopicsRegistry private _tokenTopicsRegistry;

    // @notice ClaimIssuersRegistry 合约的地址。
    IClaimIssuersRegistry private _tokenIssuersRegistry;

    // @notice IdentityRegistryStorage 合约的地址。
    IIdentityRegistryStorage private _tokenIdentityStorage;

    // keccak256(AGENT_ROLE)
    bytes32 public constant AGENT_ROLE = 0xcab5a0bfe0b79d2c4b1c2e02599fa044d115b7511f9659307cb4276950967709;

    // keccak256(OWNER_ROLE)
    bytes32 public constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;

    // @dev IdentityRegistry 合约的构造函数。
    // @param _claimIssuersRegistry 声明发行者注册表合约的地址。
    // @param _claimTopicsRegistry 声明主题注册表合约的地址。
    // @param _identityStorage 身份注册表存储合约的地址。
    // @notice 此构造函数设置了 IdentityRegistry 合约的初始状态。
    constructor(
        IClaimIssuersRegistry _claimIssuersRegistry,
        IClaimTopicsRegistry _claimTopicsRegistry,
        IIdentityRegistryStorage _identityStorage
    ) {
        require(
            address(_claimIssuersRegistry) != address(0) &&
            address(_claimTopicsRegistry) != address(0) &&
            address(_identityStorage) != address(0),
            "ERC-3643: Invalid zero address"
        );
        _grantRole(bytes32(0), _msgSender());
        _grantRole(OWNER_ROLE, _msgSender());
        _tokenTopicsRegistry = _claimTopicsRegistry;
        _tokenIssuersRegistry = _claimIssuersRegistry;
        _tokenIdentityStorage = _identityStorage;
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
        emit ClaimIssuersRegistrySet(_claimIssuersRegistry);
        emit IdentityStorageSet(_identityStorage);
    }

    // @notice 注册与用户地址关联的身份。
    // @param _userAddress 用户的地址。
    // @param _identity 用户的身份。
    // @param _country 用户的国家代码。
    // @dev 只有代理可以注册身份。
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external onlyRole(AGENT_ROLE) {
        _registerIdentity(_userAddress, _identity, _country);
    }

    // @notice 批量注册与多个用户地址关联的身份。
    // @param _userAddresses 用户地址数组。
    // @param _identities 身份数组。
    // @param _countries 国家代码数组。
    // @dev 只有代理可以批量注册身份。
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external onlyRole(AGENT_ROLE) {
        uint length = _userAddresses.length;
        require(length == _identities.length, "ERC-3643: Array size mismatch");
        require(length == _countries.length, "ERC-3643: Array size mismatch");
        for (uint256 i = 0; i < length;) {
            _registerIdentity(_userAddresses[i], _identities[i], _countries[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @notice 更新与用户地址关联的身份。
    // @param _userAddress 用户的地址。
    // @param _identity 用户的新身份。
    // @dev 只有代理可以更新身份。
    function updateIdentity(
        address _userAddress,
        IIdentity _identity
    ) external onlyRole(AGENT_ROLE) {
        IIdentity oldIdentity = _getIdentity(_userAddress);
        _tokenIdentityStorage.modifyStoredIdentity(_userAddress, _identity);
        emit IdentityUpdated(oldIdentity, _identity);
    }

    // @notice 更新与用户地址关联的国家代码。
    // @param _userAddress 用户的地址。
    // @param _country 用户的新国家代码。
    // @dev 只有代理可以更新国家代码。
    function updateCountry(
        address _userAddress,
        uint16 _country
    ) external onlyRole(AGENT_ROLE) {
        _tokenIdentityStorage.modifyStoredInvestorCountry(
            _userAddress,
            _country
        );
        emit CountryUpdated(_userAddress, _country);
    }

    // @notice 删除与用户地址关联的身份。
    // @param _userAddress 用户的地址。
    // @dev 只有代理可以删除身份。
    function deleteIdentity(
        address _userAddress
    ) external onlyRole(AGENT_ROLE) {
        IIdentity oldIdentity = _getIdentity(_userAddress);
        _tokenIdentityStorage.removeIdentityFromStorage(_userAddress);
        emit IdentityRemoved(_userAddress, oldIdentity);
    }

    // @notice 设置 IdentityRegistryStorage 合约。
    // @param _identityRegistryStorage 新的 IdentityRegistryStorage 合约的地址。
    // @dev 只有所有者可以设置 IdentityRegistryStorage 合约。
    function setIdentityRegistryStorage(
        IIdentityRegistryStorage _identityRegistryStorage
    ) external onlyRole(OWNER_ROLE) {
        _tokenIdentityStorage = _identityRegistryStorage;
        emit IdentityStorageSet(_identityRegistryStorage);
    }

    // @notice 设置 ClaimTopicsRegistry 合约。
    // @param _claimTopicsRegistry 新的 ClaimTopicsRegistry 合约的地址。
    // @dev 只有所有者可以设置 ClaimTopicsRegistry 合约。
    function setClaimTopicsRegistry(
        IClaimTopicsRegistry _claimTopicsRegistry
    ) external onlyRole(OWNER_ROLE) {
        _tokenTopicsRegistry = _claimTopicsRegistry;
        emit ClaimTopicsRegistrySet(_claimTopicsRegistry);
    }

    // @notice 设置 ClaimIssuersRegistry 合约。
    // @param _claimIssuersRegistry 新的 ClaimIssuersRegistry 合约的地址。
    // @dev 只有所有者可以设置 ClaimIssuersRegistry 合约。
    function setClaimIssuersRegistry(
        IClaimIssuersRegistry _claimIssuersRegistry
    ) external onlyRole(OWNER_ROLE) {
        _tokenIssuersRegistry = _claimIssuersRegistry;
        emit ClaimIssuersRegistrySet(_claimIssuersRegistry);
    }

    // @notice 检查用户是否基于其身份、声明主题和声明发行者已验证。
    // @param _userAddress 要检查的用户的地址。
    // @return 如果用户已验证，则返回布尔值 true；否则返回 false。
    function isVerified(address _userAddress) external view returns (bool) {
        // Get the identity of the user from the given address
        IIdentity userIdentity = _getIdentity(_userAddress);

        // If the user identity is not set (address is 0), return false
        if (address(userIdentity) == address(0)) return false;

        // Get the required claim topics for the token
        uint256[] memory claimTopics = _tokenTopicsRegistry.getClaimTopics();
        uint claimTopicsLength = claimTopics.length;

        // If there are no required claim topics, return true
        if (claimTopicsLength == 0) return true;

        // Loop over all required claim topics
        for (uint256 i = 0; i < claimTopicsLength; i++) {
            if (!_isClaimValid(userIdentity, claimTopics[i])) {
                return false;
            }
        }
        // If all checks pass, return true
        return true;
    }

    // @notice 获取投资者的国家。
    // @param _userAddress 投资者的地址。
    // @return 投资者的国家。
    function investorCountry(
        address _userAddress
    ) external view returns (uint16) {
        return _tokenIdentityStorage.storedInvestorCountry(_userAddress);
    }

    // @notice 获取发行者注册表。
    // @return 当前的发行者注册表。
    function issuersRegistry() external view returns (IClaimIssuersRegistry) {
        return _tokenIssuersRegistry;
    }

    // @notice 获取主题注册表。
    // @return 当前的主题注册表。
    function topicsRegistry() external view returns (IClaimTopicsRegistry) {
        return _tokenTopicsRegistry;
    }

    // @notice 获取身份存储。
    // @return 当前的身份存储。
    function identityStorage()
    external
    view
    returns (IIdentityRegistryStorage)
    {
        return _tokenIdentityStorage;
    }

    // @notice 检查地址是否包含在注册表中。
    // @param _userAddress 要检查的地址。
    // @return 如果地址在注册表中，则返回布尔值 true；否则返回 false。
    function contains(address _userAddress) external view returns (bool) {
        return address(identity(_userAddress)) == address(0) ? false : true;
    }

    // @notice 获取用户的身份证件。
    // @param _userAddress 用户的地址。
    // @return 用户的身份。
    function identity(address _userAddress) public view returns (IIdentity) {
        return _tokenIdentityStorage.storedIdentity(_userAddress);
    }

    // @notice 注册新身份。
    // @param _userAddress 用户的地址。
    // @param _identity 用户的身份。
    // @param _country 用户的国家。
    function _registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) private {
        _tokenIdentityStorage.addIdentityToStorage(
            _userAddress,
            _identity,
            _country
        );
        emit IdentityRegistered(_userAddress, _identity);
    }

    // @notice 获取用户的身份证件。
    // @param _userAddress 用户的地址。
    // @return 用户的身份。
    function _getIdentity(
        address _userAddress
    ) private view returns (IIdentity) {
        return _tokenIdentityStorage.storedIdentity(_userAddress);
    }

    function _isClaimValid(
        IIdentity userIdentity,
        uint256 claimTopic
    ) private view returns (bool) {
        IClaimIssuer[] memory claimIssuers = _tokenIssuersRegistry
            .getClaimIssuersForClaimTopic(claimTopic);
        uint claimIssuersLength = claimIssuers.length;

        if (claimIssuersLength == 0) {
            return false;
        }

        bytes32[] memory claimIds = new bytes32[](claimIssuersLength);

        for (uint256 i = 0; i < claimIssuersLength; i++) {
            claimIds[i] = keccak256(abi.encode(claimIssuers[i], claimTopic));
        }

        for (uint256 j = 0; j < claimIds.length; j++) {
            (
                uint256 foundClaimTopic,
                ,
                address issuer,
                bytes memory sig,
                bytes memory data,

            ) = userIdentity.getClaim(claimIds[j]);

            if (foundClaimTopic == claimTopic) {
                if (
                    _isIssuerClaimValid(
                    userIdentity,
                    issuer,
                    claimTopic,
                    sig,
                    data
                )
                ) {
                    return true;
                }
            } else if (j == claimIds.length - 1) {
                return false;
            }
        }

        return false;
    }

    // @param userIdentity 与声明相关的身份合约。
    // @param issuer 声明发行者的地址。
    // @param claimTopic 声明的主题。
    // @param sig 声明的签名。
    // @param data 声明的数据字段。
    // @return claimValid 如果声明有效，则返回 true；否则返回 false。
    function _isIssuerClaimValid(
        IIdentity userIdentity,
        address issuer,
        uint claimTopic,
        bytes memory sig,
        bytes memory data
    ) private view returns (bool) {
        try
        IClaimIssuer(issuer).isClaimValid(
            userIdentity,
            claimTopic,
            sig,
            data
        )
        returns (bool _validity) {
            return _validity;
        } catch {
            return false;
        }
    }
}
