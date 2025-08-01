// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./interface/ICompliance.sol";
import "../token/IToken.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

contract BasicCompliance is ICompliance, AccessControl {
    // 代理与状态之间的映射
    mapping(address => bool) private _tokenAgentsList;
    // 与合规合约关联的代币映射
    IToken public tokenBound;

    // keccak256(ADMIN_ROLE)
    bytes32 public constant ADMIN_ROLE =
        0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;

    // keccak256(TOKEN_ROLE)
    bytes32 public constant TOKEN_ROLE =
        0xa7197c38d9c4c7450c7f2cd20d0a17cbe7c344190d6c82a6b49a146e62439ae4;

    constructor() {
        _grantRole(0x00, _msgSender());
        _grantRole(ADMIN_ROLE, _msgSender());
        console.log("GOT INTO CONSTRUCTOR");
    }

    /**
     *  @dev 查看 {ICompliance-bindToken}。
     */
    function bindToken(address _token) external {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                address(tokenBound) == address(0),
            unicode"ERC-3643: 调用者未授权"
        );
        tokenBound = IToken(_token);
        emit TokenBound(_token);
    }

    /**
     *  @dev 查看 {ICompliance-unbindToken}。
     */
    function unbindToken(address _token) external {
        require(
            hasRole(ADMIN_ROLE, _msgSender()) ||
                hasRole(TOKEN_ROLE, _msgSender()),
            unicode"ERC-3643: 调用者未授权"
        );
        require(_token == address(tokenBound), unicode"ERC-3643: 代币未绑定");
        delete tokenBound;
        emit TokenUnbound(_token);
    }

    /*
     *  @dev 查看 {ICompliance-transferred}。
     */
    function transferred(address _from, address _to, uint256 _value) external {}

    /**
     *  @dev 查看 {ICompliance-created}。
     */

    function created(address _to, uint256 _value) external {}

    /**
     *  @dev 查看 {ICompliance-destroyed}。
     */
    function destroyed(address _from, uint256 _value) external {}

    /**
     *  @dev 查看 {ICompliance-canTransfer}。
     */
    function canTransfer(
        address  /*_from*/,
        address  /*_to*/,
        uint256  /*_value*/
    ) external view returns (bool) {
        return true;
    }

    /**
     *  @dev 查看 {ICompliance-isTokenBound}。
     */
    function isTokenBound(address _token) external view returns (bool) {
        return (_token == address(tokenBound));
    }
}
