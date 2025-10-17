// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";

interface IIdentityRegistryStorage {
    // events

    /**
     *  当一个身份被注册到存储合约中时发出此事件。
     *  该事件由 'addIdentityToStorage' 函数触发。
     *  `investorAddress` 是投资者钱包的地址。
     *  `identity` 是身份智能合约的地址（OnchainID）。
     */
    event IdentityStored(
        address indexed investorAddress,
        IIdentity indexed identity
    );

    /**
     *  当一个身份从存储合约中移除时发出此事件。
     *  该事件由 'removeIdentityFromStorage' 函数触发。
     *  `investorAddress` 是投资者钱包的地址。
     *  `identity` 是身份智能合约的地址（OnchainID）。
     */
    event IdentityUnstored(
        address indexed investorAddress,
        IIdentity indexed identity
    );

    /**
     *  当一个身份被更新时发出此事件。
     *  该事件由 'modifyStoredIdentity' 函数触发。
     *  `oldIdentity` 是要更新的旧身份合约的地址。
     *  `newIdentity` 是新身份合约的地址。
     */
    event IdentityModified(
        IIdentity indexed oldIdentity,
        IIdentity indexed newIdentity
    );

    /**
     *  当一个身份的国家被更新时发出此事件。
     *  该事件由 'modifyStoredInvestorCountry' 函数触发。
     *  `investorAddress` 是其国家被更新的地址。
     *  `country` 是新国家的数字代码（ISO 3166-1）。
     */
    event CountryModified(
        address indexed investorAddress,
        uint16 indexed country
    );

    /**
     *  当一个身份注册表被绑定到存储合约时发出此事件。
     *  该事件由 'bindIdentityRegistry' 函数触发。
     *  `identityRegistry` 是添加的身份注册表的地址。
     */
    event IdentityRegistryBound(address indexed identityRegistry);

    /**
     *  当一个身份注册表从存储合约中解绑时发出此事件。
     *  该事件由 'unbindIdentityRegistry' 函数触发。
     *  `identityRegistry` 是移除的身份注册表的地址。
     */
    event IdentityRegistryUnbound(address indexed identityRegistry);

    // functions

    /**
     *  @dev 向存储中添加与用户地址对应的身份合约。
     *  要求用户尚未注册身份合约。
     *  此函数只能由设置为智能合约代理的地址调用
     *  @param _userAddress 用户的地址
     *  @param _identity 用户身份合约的地址
     *  @param _country 投资者的国家
     *  触发 `IdentityStored` 事件
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev 从存储中移除用户。
     *  要求用户已部署将被删除的身份合约。
     *  此函数只能由设置为智能合约代理的地址调用
     *  @param _userAddress 要移除的用户地址
     *  触发 `IdentityUnstored` 事件
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     *  @dev 更新与用户地址对应的国家。
     *  要求用户已部署将被替换的身份合约。
     *  此函数只能由设置为智能合约代理的地址调用
     *  @param _userAddress 用户的地址
     *  @param _country 用户的新国家
     *  触发 `CountryModified` 事件
     */
    function modifyStoredInvestorCountry(
        address _userAddress,
        uint16 _country
    ) external;

    /**
     *  @dev 更新与用户地址对应的身份合约。
     *  要求用户地址应为身份合约的所有者。
     *  要求用户已部署将被替换的身份合约。
     *  此函数只能由设置为智能合约代理的地址调用
     *  @param _userAddress 用户的地址
     *  @param _identity 用户新身份合约的地址
     *  触发 `IdentityModified` 事件
     */
    function modifyStoredIdentity(
        address _userAddress,
        IIdentity _identity
    ) external;

    /**
     *  @notice 添加身份注册表作为身份注册存储合约的代理。
     *  此函数只能由设置为智能合约所有者的钱包调用
     *  此函数将身份注册表添加到链接到存储合约的身份注册表列表中
     *  不能将超过300个IR绑定到1个IRS
     *  @param _identityRegistry 要添加的身份注册表地址。
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice 移除身份注册表作为身份注册存储合约的代理。
     *  此函数只能由设置为智能合约所有者的钱包调用
     *  此函数从链接到存储合约的身份注册表列表中移除身份注册表
     *  @param _identityRegistry 要移除的身份注册表地址。
     */
    function unbindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @dev 返回链接到存储合约的身份注册表
     */
    function linkedIdentityRegistries()
        external
        view
        returns (address[] memory);

    /**
     *  @dev 返回投资者的链上ID。
     *  @param _userAddress 投资者的钱包
     */
    function storedIdentity(
        address _userAddress
    ) external view returns (IIdentity);

    /**
     *  @dev 返回投资者的国家代码。
     *  @param _userAddress 投资者的钱包
     */
    function storedInvestorCountry(
        address _userAddress
    ) external view returns (uint16);
}