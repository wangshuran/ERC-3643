// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface ICompliance {
    /**
     * 当代币与合规合约绑定后触发此事件
     * 该事件由bindToken函数触发
     * `_token` 是被绑定的代币地址
     */
    event TokenBound(address _token);

    /**
     * 当代币与合规合约解除绑定后触发此事件
     * 该事件由unbindToken函数触发
     * `_token` 是被解除绑定的代币地址
     */
    event TokenUnbound(address _token);

    /**
     * @dev 将代币与合规合约绑定
     * @param _token 要绑定的代币地址
     * 触发TokenBound事件
     */
    function bindToken(address _token) external;

    /**
     * @dev 将代币与合规合约解除绑定
     * @param _token 要解除绑定的代币地址
     * 触发TokenUnbound事件
     */
    function unbindToken(address _token) external;

    /**
     * @dev 每当代币从一个钱包转移到另一个钱包时调用此函数
     * 该函数可以更新合规合约中的状态变量
     * 这些状态变量将被`canTransfer`函数用于判断转账是否合规，
     * 判断依据包括这些状态变量的值和合规智能合约的参数
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _amount 转账涉及的代币数量
     */
    function transferred(address _from, address _to, uint256 _amount) external;

    /**
     * @dev 每当代币在钱包中被创建（铸造）时调用此函数
     * 该函数可以更新合规合约中的状态变量
     * 这些状态变量将被`canTransfer`函数用于判断转账是否合规，
     * 判断依据包括这些状态变量的值和合规智能合约的参数
     * @param _to 接收者地址
     * @param _amount 涉及的代币数量
     */
    function created(address _to, uint256 _amount) external;

    /**
     * @dev 每当代币被销毁时调用此函数
     * 该函数可以更新合规合约中的状态变量
     * 这些状态变量将被`canTransfer`函数用于判断转账是否合规，
     * 判断依据包括这些状态变量的值和合规智能合约的参数
     * @param _from 代币持有者地址（销毁来源）
     * @param _amount 销毁涉及的代币数量
     */
    function destroyed(address _from, uint256 _amount) external;

    /**
     * @dev 判断给定地址是否对应与合规合约绑定的代币
     * @param _token 代币地址
     */
    function isTokenBound(address _token) external view returns (bool);

    /**
     * @dev 检查转账是否合规
     * 默认合规逻辑始终返回true
     * 只读函数，不能用于递增计数器、触发事件等操作
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _amount 转账涉及的代币数量
     */
    function canTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external view returns (bool);
}
