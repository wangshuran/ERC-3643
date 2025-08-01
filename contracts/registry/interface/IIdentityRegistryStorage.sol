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
     *  @dev adds an identity contract corresponding to a user address in the storage.
     *  Requires that the user doesn't have an identity contract already registered.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's identity contract
     *  @param _country The country of the investor
     *  emits `IdentityStored` event
     */
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external;

    /**
     *  @dev Removes an user from the storage.
     *  Requires that the user have an identity contract already deployed that will be deleted.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user to be removed
     *  emits `IdentityUnstored` event
     */
    function removeIdentityFromStorage(address _userAddress) external;

    /**
     *  @dev Updates the country corresponding to a user address.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _country The new country of the user
     *  emits `CountryModified` event
     */
    function modifyStoredInvestorCountry(
        address _userAddress,
        uint16 _country
    ) external;

    /**
     *  @dev Updates an identity contract corresponding to a user address.
     *  Requires that the user address should be the owner of the identity contract.
     *  Requires that the user should have an identity contract already deployed that will be replaced.
     *  This function can only be called by an address set as agent of the smart contract
     *  @param _userAddress The address of the user
     *  @param _identity The address of the user's new identity contract
     *  emits `IdentityModified` event
     */
    function modifyStoredIdentity(
        address _userAddress,
        IIdentity _identity
    ) external;

    /**
     *  @notice Adds an identity registry as agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function adds the identity registry to the list of identityRegistries linked to the storage contract
     *  cannot bind more than 300 IR to 1 IRS
     *  @param _identityRegistry The identity registry address to add.
     */
    function bindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @notice Removes an identity registry from being agent of the Identity Registry Storage Contract.
     *  This function can only be called by the wallet set as owner of the smart contract
     *  This function removes the identity registry from the list of identityRegistries linked to the storage contract
     *  @param _identityRegistry The identity registry address to remove.
     */
    function unbindIdentityRegistry(address _identityRegistry) external;

    /**
     *  @dev Returns the identity registries linked to the storage contract
     */
    function linkedIdentityRegistries()
        external
        view
        returns (address[] memory);

    /**
     *  @dev Returns the onchainID of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedIdentity(
        address _userAddress
    ) external view returns (IIdentity);

    /**
     *  @dev Returns the country code of an investor.
     *  @param _userAddress The wallet of the investor
     */
    function storedInvestorCountry(
        address _userAddress
    ) external view returns (uint16);
}
