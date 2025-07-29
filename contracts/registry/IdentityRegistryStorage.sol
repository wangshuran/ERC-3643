pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";
import "./interface/IIdentityRegistryStorage.sol";

// @title ERC-3643 - 身份注册表存储
// @notice 存储用户身份及其所属国家。
contract IdentityRegistryStorage is IIdentityRegistryStorage, AccessControl {
    // @dev struct containing the identity contract and the country of the user
    struct Identity {
        // @dev Identity contract of the user
        IIdentity identityContract;
        // @dev Country of the user
        uint16 investorCountry;
    }

    // keccak256(AGENT_ROLE)
    bytes32 public constant AGENT_ROLE = 0xcab5a0bfe0b79d2c4b1c2e02599fa044d115b7511f9659307cb4276950967709;

    // keccak256(OWNER_ROLE)
    bytes32 public constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;

    // @dev 映射用户地址与其对应的身份
    mapping(address => Identity) internal _identities;

    // @dev 存储与此存储关联的身份注册表数组
    address[] internal _identityRegistries;

    constructor() {
        _grantRole(bytes32(0), _msgSender());
        _grantRole(AGENT_ROLE, _msgSender());
        _grantRole(OWNER_ROLE, _msgSender());
        console.log(unicode"||||||||||||||||||||||||||||||||这是构造函数中的所有者地址");
        console.log(_msgSender());
    }

    // @notice 将新身份添加到存储中
    // @param _userAddress 用户地址
    // @param _identity 用户的身份合约
    // @param _country 用户的国家
    function addIdentityToStorage(
        address _userAddress,
        IIdentity _identity,
        uint16 _country
    ) external onlyRole(AGENT_ROLE) {
        require(
            _userAddress != address(0) && address(_identity) != address(0),
            unicode"ERC-3643: 无效的零地址"
        );
        require(
            address(_identities[_userAddress].identityContract) == address(0),
            unicode"ERC-3643: 已经存储"
        );
        _identities[_userAddress].identityContract = _identity;
        _identities[_userAddress].investorCountry = _country;
        emit IdentityStored(_userAddress, _identity);
    }

    // @notice 修改存储中的用户身份
    // @param _userAddress 用户地址
    // @param _identity 用户的新身份合约
    function modifyStoredIdentity(
        address _userAddress,
        IIdentity _identity
    ) external onlyRole(AGENT_ROLE) {
        require(
            _userAddress != address(0) && address(_identity) != address(0),
            unicode"ERC-3643: Invalid zero address"
        );
        require(
            address(_identities[_userAddress].identityContract) != address(0),
            unicode"ERC-3643: Address not stored"
        );
        IIdentity oldIdentity = _identities[_userAddress].identityContract;
        _identities[_userAddress].identityContract = _identity;
        emit IdentityModified(oldIdentity, _identity);
    }

    // @notice 修改存储的投资者国家
    // @param _userAddress 用户地址
    // @param _country 用户的新国家
    function modifyStoredInvestorCountry(
        address _userAddress,
        uint16 _country
    ) external onlyRole(AGENT_ROLE) {
        require(_userAddress != address(0), unicode"ERC-3643: 无效的零地址");
        require(
            address(_identities[_userAddress].identityContract) != address(0),
            unicode"ERC-3643: 地址未存储"
        );
        _identities[_userAddress].investorCountry = _country;
        emit CountryModified(_userAddress, _country);
    }

    // @notice 从存储中移除用户身份
    // @param _userAddress 用户地址
    function removeIdentityFromStorage(
        address _userAddress
    ) external onlyRole(AGENT_ROLE) {
        require(_userAddress != address(0), unicode"ERC-3643: 无效的零地址");
        require(
            address(_identities[_userAddress].identityContract) != address(0),
            unicode"ERC-3643: 地址未存储"
        );
        IIdentity oldIdentity = _identities[_userAddress].identityContract;
        delete _identities[_userAddress];
        emit IdentityUnstored(_userAddress, oldIdentity);
    }

    // @notice 将身份注册表链接到此存储
    // @param _identityRegistry 身份注册表的地址
    function bindIdentityRegistry(
        address _identityRegistry
    ) external onlyRole(OWNER_ROLE) {
        console.log(unicode"进入bindIdentityRegistry函数");
        require(
            _identityRegistry != address(0),
            unicode"ERC-3643: 无效的零地址"
        );
        console.log(unicode"进入bindIdentityRegistry函数");

        _grantRole(AGENT_ROLE, _identityRegistry);
        console.log(unicode"进入bindIdentityRegistry函数");
        _identityRegistries.push(_identityRegistry);
        console.log(unicode"进入bindIdentityRegistry函数");
        emit IdentityRegistryBound(_identityRegistry);
    }

    // @notice 从存储中解绑一个身份注册表
    // @param _identityRegistry 身份注册表的地址
    function unbindIdentityRegistry(
        address _identityRegistry
    ) external onlyRole(OWNER_ROLE) {
        require(
            _identityRegistry != address(0),
            unicode"ERC-3643: Invalid zero address"
        );
        require(
            _identityRegistries.length != 0,
            unicode"ERC-3643: No identity registry"
        );
        uint256 length = _identityRegistries.length;
        for (uint256 i = 0; i < length;) {
            if (_identityRegistries[i] == _identityRegistry) {
                _identityRegistries[i] = _identityRegistries[length - 1];
                _identityRegistries.pop();
                break;
            }
            unchecked {
                ++i;
            }
        }
        _revokeRole(AGENT_ROLE, _identityRegistry);
        emit IdentityRegistryUnbound(_identityRegistry);
    }

    // @notice 返回所有已绑定的身份注册表
    // @return 已绑定身份注册表的地址数组
    function linkedIdentityRegistries()
    external
    view
    returns (address[] memory)
    {
        return _identityRegistries;
    }

    // @notice 返回用户的已存储身份
    // @param _userAddress 用户地址
    // @return 用户的身份合约
    function storedIdentity(
        address _userAddress
    ) external view returns (IIdentity) {
        return _identities[_userAddress].identityContract;
    }

    // @notice 返回用户的已存储投资者国家
    // @param _userAddress 用户的地址
    // @return 用户的国家
    function storedInvestorCountry(
        address _userAddress
    ) external view returns (uint16) {
        return _identities[_userAddress].investorCountry;
    }
}
