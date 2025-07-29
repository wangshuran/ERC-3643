pragma solidity 0.8.17;

import "./IClaimIssuersRegistry.sol";
import "./IClaimTopicsRegistry.sol";
import "./IIdentityRegistryStorage.sol";

import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";

interface IIdentityRegistry {
    /**
     * 当 ClaimTopicsRegistry 被设置为 IdentityRegistry 的一部分时发出此事件。
     * 该事件由 IdentityRegistry 构造函数触发。
     * `claimTopicsRegistry` 是 Claim Topics Registry 合约的地址。
     */
    event ClaimTopicsRegistrySet(
        IClaimTopicsRegistry indexed claimTopicsRegistry
    );

    /**
     * 当 IdentityRegistryStorage 被设置为 IdentityRegistry 的一部分时发出此事件。
     * 该事件由 IdentityRegistry 构造函数触发。
     * `identityStorage` 是 Identity Registry Storage 合约的地址。
     */
    event IdentityStorageSet(IIdentityRegistryStorage indexed identityStorage);

    /**
     * 当 ClaimIssuersRegistry 被设置为 IdentityRegistry 的一部分时发出此事件。
     * 该事件由 IdentityRegistry 构造函数触发。
     * `claimIssuersRegistry` 是 Claim Issuers Registry 合约的地址。
     */
    event ClaimIssuersRegistrySet(
        IClaimIssuersRegistry indexed claimIssuersRegistry
    );

    /**
     * 当一个身份被注册到身份注册表中时发出此事件。
     * 该事件由 'registerIdentity' 函数触发。
     * `investorAddress` 是投资者钱包的地址。
     * `identity` 是身份智能合约的地址（OnchainID）。
     */
    event IdentityRegistered(
        address indexed investorAddress,
        IIdentity indexed identity
    );

    /**
     * 当一个身份从身份注册表中移除时发出此事件。
     * 该事件由 'deleteIdentity' 函数触发。
     * `investorAddress` 是投资者钱包的地址。
     * `identity` 是身份智能合约的地址（OnchainID）。
     */
    event IdentityRemoved(
        address indexed investorAddress,
        IIdentity indexed identity
    );

    /**
     * 当一个身份被更新时发出此事件。
     * 该事件由 'updateIdentity' 函数触发。
     * `oldIdentity` 是要更新的旧身份合约的地址。
     * `newIdentity` 是新身份合约的地址。
     */
    event IdentityUpdated(
        IIdentity indexed oldIdentity,
        IIdentity indexed newIdentity
    );

    /**
     * 当一个身份的国家被更新时发出此事件。
     * 该事件由 'updateCountry' 函数触发。
     * `investorAddress` 是其国家被更新的地址。
     * `country` 是新国家的数字代码（ISO 3166-1）。
     */
    event CountryUpdated(
        address indexed investorAddress,
        uint16 indexed country
    );

    /**
     * @dev 注册与用户地址关联的身份。
     * 要求用户没有已经注册的身份合约。
     * 此函数只能由设置为智能合约代理的钱包调用。
     * @param _userAddress 用户的地址。
     * @param _identity 用户的身份合约地址。
     * @param _country 投资者的国家。
     * 触发 `IdentityRegistered` 事件。
     */
    function registerIdentity(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     * @dev 从身份注册表中移除用户。
     * 要求用户已经部署了一个身份合约，该合约将被删除。
     * 此函数只能由设置为智能合约代理的钱包调用。
     * @param _userAddress 要移除的用户的地址。
     * 触发 `IdentityRemoved` 事件。
     */
    function deleteIdentity(address _userAddress) external;

    /**
     * @dev 替换当前的 identityRegistryStorage 合约为新的合约。
     * 此函数只能由设置为智能合约所有者的钱包调用。
     * @param _identityRegistryStorage 新的 Identity Registry Storage 合约的地址。
     * 触发 `IdentityStorageSet` 事件。
     */
    function setIdentityRegistryStorage(
        IIdentityRegistryStorage _identityRegistryStorage
    ) external;

    /**
     * @dev 替换当前的 claimTopicsRegistry 合约为新的合约。
     * 此函数只能由设置为智能合约所有者的钱包调用。
     * @param _claimTopicsRegistry 新的 Claim Topics Registry 合约的地址。
     * 触发 `ClaimTopicsRegistrySet` 事件。
     */
    function setClaimTopicsRegistry(
        IClaimTopicsRegistry _claimTopicsRegistry
    ) external;

    /**
     * @dev 替换当前的 claimIssuersRegistry 合约为新的合约。
     * 此函数只能由设置为智能合约所有者的钱包调用。
     * @param _claimIssuersRegistry 新的 Claim Issuers Registry 合约的地址。
     * 触发 `ClaimIssuersRegistrySet` 事件。
     */
    function setClaimIssuersRegistry(
        IClaimIssuersRegistry _claimIssuersRegistry
    ) external;

    /**
     * @dev 更新与用户地址关联的国家。
     * 要求用户已经部署了一个身份合约，该合约将被替换。
     * 此函数只能由设置为智能合约代理的钱包调用。
     * @param _userAddress 用户的地址。
     * @param _country 用户的新国家。
     * 触发 `CountryUpdated` 事件。
     */
    function updateCountry(address _userAddress, uint16 _country) external;

    /**
     * @dev 更新与用户地址关联的身份合约。
     * 要求用户地址是身份合约的所有者。
     * 要求用户已经部署了一个身份合约，该合约将被替换。
     * 此函数只能由设置为智能合约代理的钱包调用。
     * @param _userAddress 用户的地址。
     * @param _identity 用户的新身份合约地址。
     * 触发 `IdentityUpdated` 事件。
     */
    function updateIdentity(address _userAddress, IIdentity _identity) external;

    /**
     * @dev 允许批量注册身份的函数。
     * 此函数只能由设置为智能合约代理的钱包调用。
     * 要求没有任何用户已经注册了身份合约。
     * 重要提示：如果 `_userAddresses.length` 过高，此交易可能会超出 gas 限制，请谨慎使用，否则可能会因“OUT OF GAS”而导致交易费用损失。
     * @param _userAddresses 用户的地址数组。
     * @param _identities 对应身份合约的地址数组。
     * @param _countries 对应投资者的国家数组。
     * 触发 `_userAddresses.length` 次 `IdentityRegistered` 事件。
     */
    function batchRegisterIdentity(
        address[] calldata _userAddresses,
        IIdentity[] calldata _identities,
        uint16[] calldata _countries
    ) external;

    /**
     * @dev 此函数检查钱包是否在身份注册表中注册了身份。
     * @param _userAddress 要检查的用户的地址。
     * @return 如果地址包含在身份注册表中，则返回布尔值 true；否则返回 false。
     */
    function contains(address _userAddress) external view returns (bool);

    /**
     * @dev 此函数检查提供用户地址对应的身份合约是否具有所需的声明，基于从声明发行者注册表和声明主题注册表获取的数据。
     * @param _userAddress 要验证的用户的地址。
     * @return 如果地址已验证，则返回布尔值 true；否则返回 false。
     */
    function isVerified(address _userAddress) external view returns (bool);

    /**
     * @dev 返回投资者的链上 ID。
     * @param _userAddress 投资者的钱包地址。
     */
    function identity(address _userAddress) external view returns (IIdentity);

    /**
     * @dev 返回投资者的国家代码。
     * @param _userAddress 投资者的钱包地址。
     */
    function investorCountry(
        address _userAddress
    ) external view returns (uint16);

    /**
     * @dev 返回与当前身份注册表关联的 IdentityRegistryStorage。
     */
    function identityStorage() external view returns (IIdentityRegistryStorage);

    /**
     * @dev 返回与当前身份注册表关联的 ClaimIssuersRegistry。
     */
    function issuersRegistry() external view returns (IClaimIssuersRegistry);

    /**
     * @dev 返回与当前身份注册表关联的 ClaimTopicsRegistry。
     */
    function topicsRegistry() external view returns (IClaimTopicsRegistry);
}