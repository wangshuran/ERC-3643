pragma solidity 0.8.17;

import "../registry/interface/IIdentityRegistry.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @dev 接口定义
interface IToken is IERC20 {
    // 事件定义

    /**
     * 当链上ID（onchainID）被更新时触发此事件。
     * 该事件由token的初始化函数和setOnchainID函数触发
     * `_newOnchainID` 是token的链上ID地址
     */
    event UpdatedOnchainID(address indexed _newOnchainID);

    /**
     * 当为token设置身份注册表（IdentityRegistry）时触发此事件
     * 该事件由token的构造函数和setIdentityRegistry函数触发
     * `_identityRegistry` 是token的身份注册表地址
     */
    event IdentityRegistryAdded(address indexed _identityRegistry);

    /**
     * 当为token设置合规合约（Compliance）时触发此事件
     * 该事件由token的构造函数和setCompliance函数触发
     * `_compliance` 是token的合规合约地址
     */
    event ComplianceAdded(address indexed _compliance);

    /**
     * 当投资者成功找回其代币时触发此事件
     * 该事件由recoveryAddress函数触发
     * `_lostWallet` 是投资者丢失访问权限的钱包地址
     * `_newWallet` 是投资者提供的用于找回代币的新钱包地址
     * `_investorOnchainID` 是请求找回代币的投资者的链上ID地址
     */
    event RecoverySuccess(
        address indexed _lostWallet,
        address indexed _newWallet,
        address indexed _investorOnchainID
    );

    /**
     * 当投资者的钱包被冻结或解冻时触发此事件
     * 该事件由setAddressFrozen和batchSetAddressFrozen函数触发
     * `_userAddress` 是受冻结状态影响的投资者钱包地址
     * `_isFrozen` 是钱包的冻结状态
     * 若`_isFrozen`为`true`，则事件触发后钱包被冻结
     * 若`_isFrozen`为`false`，则事件触发后钱包被解冻
     * `_owner` 是调用函数冻结钱包的代理地址
     */
    event AddressFrozen(
        address indexed _userAddress,
        bool indexed _isFrozen,
        address indexed _owner
    );

    /**
     * 当钱包上一定数量的代币被冻结时触发此事件
     * 该事件由freezePartialTokens和batchFreezePartialTokens函数触发
     * `_userAddress` 是受冻结影响的投资者钱包地址
     * `_amount` 是被冻结的代币数量
     */
    event TokensFrozen(
        address indexed _userAddress,
        uint256 _amount
    );

    /**
     * 当钱包上一定数量的代币被解冻时触发此事件
     * 该事件由unfreezePartialTokens和batchUnfreezePartialTokens函数触发
     * `_userAddress` 是受解冻影响的投资者钱包地址
     * `_amount` 是被解冻的代币数量
     */
    event TokensUnfrozen(
        address indexed _userAddress,
        uint256 _amount
    );

    /**
     * @dev 设置代币的链上ID
     * @param _onchainID 要设置的链上ID地址
     * 仅代币智能合约的所有者可调用此函数
     * 触发`UpdatedTokenInformation`事件
     */
    function setOnchainID(address _onchainID) external;

    /**
     * @dev 暂停代币合约，合约暂停后投资者无法再转移代币
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`Paused`事件
     */
    function pause() external;

    /**
     * @dev 解除代币合约的暂停状态，合约解除暂停后：
     * 若投资者的钱包未被冻结且可转移金额≤可用代币量（未冻结代币），则可转移代币
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`Unpaused`事件
     */
    function unpause() external;

    /**
     * @dev 设置某个地址在此代币中的冻结状态
     * @param _userAddress 要更新冻结状态的地址
     * @param _freeze 地址的冻结状态
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`AddressFrozen`事件
     */
    function setAddressFrozen(address _userAddress, bool _freeze) external;

    /**
     * @dev 为指定地址冻结特定数量的代币
     * @param _userAddress 要更新冻结代币的地址
     * @param _amount 要冻结的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`TokensFrozen`事件
     */
    function freezePartialTokens(
        address _userAddress,
        uint256 _amount
    ) external;

    /**
     * @dev 为指定地址解冻特定数量的代币
     * @param _userAddress 要更新解冻代币的地址
     * @param _amount 要解冻的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`TokensUnfrozen`事件
     */
    function unfreezePartialTokens(
        address _userAddress,
        uint256 _amount
    ) external;

    /**
     * @dev 为代币设置身份注册表
     * @param _identityRegistry 要设置的身份注册表地址
     * 仅代币智能合约的所有者可调用此函数
     * 触发`IdentityRegistryAdded`事件
     */
    function setIdentityRegistry(address _identityRegistry) external;

    /**
     * @dev 设置代币的合规合约
     * @param _compliance 要设置的合规合约地址
     * 仅代币智能合约的所有者可调用此函数
     * 调用合规合约上的bindToken函数
     * 触发`ComplianceAdded`事件
     */
    function setCompliance(address _compliance) external;

    /**
     * @dev 强制在两个白名单钱包之间转移代币
     * 若`from`地址的可用代币（未冻结代币）不足，但总余额≥`amount`：
     * 则减少冻结代币数量以确保有足够的可用代币完成转移，此时转移后`from`地址的剩余余额将100%由冻结代币组成
     * 要求`to`地址是已验证地址
     * @param _from 发送者地址
     * @param _to 接收者地址
     * @param _amount 要转移的代币数量
     * @return 成功返回`true`，失败则回滚
     * 此函数仅可由被设置为代币代理的钱包调用
     * 若`_amount`大于`_from`的可用余额，触发`TokensUnfrozen`事件
     * 触发`Transfer`事件
     */
    function forcedTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    /**
     * @dev 在钱包上铸造代币
     * 对默认铸造方法的改进。仅当地址是安全代币的已验证地址时，才可向该地址铸造代币
     * @param _to 代币铸造的目标地址
     * @param _amount 要铸造的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`Transfer`事件
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @dev 在钱包上销毁代币
     * 若`account`地址的可用代币（未冻结代币）不足，但总余额≥`value`数量：
     * 则减少冻结代币数量以确保有足够的可用代币完成销毁，此时销毁后`account`地址的剩余余额将100%由冻结代币组成
     * @param _userAddress 要从中销毁代币的地址
     * @param _amount 要销毁的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 若`_amount`大于`_userAddress`的可用余额，触发`TokensUnfrozen`事件
     * 触发`Transfer`事件
     */
    function burn(address _userAddress, uint256 _amount) external;

    /**
     * @dev 用于投资者将代币从丢失的钱包强制转移到新钱包的恢复函数
     * @param _lostWallet 投资者丢失的钱包
     * @param _newWallet 投资者提供的用于接收转移代币的新钱包
     * @param _investorOnchainID 请求恢复的投资者的链上ID
     * 此函数仅可由被设置为代币代理的钱包调用
     * 若恢复成功且丢失的钱包上有冻结代币，触发`TokensUnfrozen`事件
     * 若恢复成功，触发`Transfer`事件
     * 若恢复成功，触发`RecoverySuccess`事件
     * 若恢复失败，触发`RecoveryFails`事件
     */
    function recoveryAddress(
        address _lostWallet,
        address _newWallet,
        address _investorOnchainID
    ) external returns (bool);

    /**
     * @dev 允许批量执行转移的函数
     * 要求msg.sender和`to`地址未被冻结
     * 要求总价值不超过可用余额
     * 要求`to`地址均为已验证地址
     * 重要提示：若`_toList.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _toList 接收者地址列表
     * @param _amounts 对应接收者的代币转移数量
     * 触发`_toList.length`个`Transfer`事件
     */
    function batchTransfer(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 允许批量执行强制转移的函数
     * 要求`_amounts[i]`不超过`_fromList[i]`的可用余额
     * 要求`_toList`地址均为已验证地址
     * 重要提示：若`_fromList.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _fromList 发送者地址列表
     * @param _toList 接收者地址列表
     * @param _amounts 对应接收者的代币转移数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 若`_amounts[i]`大于`_fromList[i]`的可用余额，触发`TokensUnfrozen`事件
     * 触发`_fromList.length`个`Transfer`事件
     */
    function batchForcedTransfer(
        address[] calldata _fromList,
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 允许批量铸造代币的函数
     * 要求`_toList`地址均为已验证地址
     * 重要提示：若`_toList.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _toList 接收者地址列表
     * @param _amounts 对应接收者的代币铸造数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`_toList.length`个`Transfer`事件
     */
    function batchMint(
        address[] calldata _toList,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 允许批量销毁代币的函数
     * 要求`_userAddresses`地址均为已验证地址
     * 重要提示：若`_userAddresses.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _userAddresses 受销毁影响的钱包地址列表
     * @param _amounts 对应钱包的代币销毁数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`_userAddresses.length`个`Transfer`事件
     */
    function batchBurn(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 允许批量设置冻结地址的函数
     * 重要提示：若`_userAddresses.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _userAddresses 要更新冻结状态的地址列表
     * @param _freeze 对应地址的冻结状态
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`_userAddresses.length`个`AddressFrozen`事件
     */
    function batchSetAddressFrozen(
        address[] calldata _userAddresses,
        bool[] calldata _freeze
    ) external;

    /**
     * @dev 允许批量部分冻结代币的函数
     * 重要提示：若`_userAddresses.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _userAddresses 需要冻结代币的地址列表
     * @param _amounts 对应地址要冻结的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`_userAddresses.length`个`TokensFrozen`事件
     */
    function batchFreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 允许批量部分解冻代币的函数
     * 重要提示：若`_userAddresses.length`过大，此交易可能超过Gas限制，使用时需谨慎，否则可能因"Gas不足"损失交易费用
     * @param _userAddresses 需要解冻代币的地址列表
     * @param _amounts 对应地址要解冻的代币数量
     * 此函数仅可由被设置为代币代理的钱包调用
     * 触发`_userAddresses.length`个`TokensUnfrozen`事件
     */
    function batchUnfreezePartialTokens(
        address[] calldata _userAddresses,
        uint256[] calldata _amounts
    ) external;

    /**
     * @dev 返回代币的小数位数，用于用户展示
     * 例如，若`decimals`等于`2`，则505个代币应向用户显示为5.05（505 / 10^2）
     * 注意：此信息仅用于_展示_目的，绝不影响合约的任何算术运算，包括balanceOf()和transfer()
     */
    function decimals() external view returns (uint8);

    /**
     * @dev 返回代币名称
     */
    function name() external view returns (string memory);

    /**
     * @dev 返回代币的链上ID地址
     * 代币的链上ID包含所有关于代币的可用信息，由代币发行方或其代理管理
     */
    function onchainID() external view returns (address);

    /**
     * @dev 返回代币符号，通常是名称的缩写
     */
    function symbol() external view returns (string memory);

    /**
     * @dev 返回代币的TREX版本
     * 当前版本为3.0.0
     */
    function version() external view returns (string memory);

    /**
     * @dev 返回与代币关联的身份注册表
     */
    function identityRegistry() external view returns (IIdentityRegistry);

    /**
     * @dev 返回与代币关联的合规合约
     */
    function compliance() external view returns (address);

    /**
     * @dev 返回钱包的冻结状态
     * 若isFrozen返回`true`，则钱包被冻结
     * 若isFrozen返回`false`，则钱包未被冻结
     * isFrozen返回`true`并不意味着余额可用，代币可能被部分冻结或整个代币可能被暂停功能冻结
     * @param _userAddress 调用isFrozen的钱包地址
     */
    function isFrozen(address _userAddress) external view returns (bool);

    /**
     * @dev 返回钱包上被部分冻结的代币数量
     * 冻结的代币数量始终≤钱包的总余额
     * @param _userAddress 调用getFrozenTokens的钱包地址
     */
    function getFrozenTokens(
        address _userAddress
    ) external view returns (uint256);
}