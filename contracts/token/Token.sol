// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./IToken.sol";
import "@onchain-id/solidity/contracts/interface/IIdentity.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../compliance/interface/ICompliance.sol";

// @title ERC-3643 - T-Rex代币（版本RAPTOR-5.0.0）
// @notice 一个符合ERC-3643标准的代币，带有链上验证器和合规检查功能
contract Token is IToken, AccessControl, Pausable {
    // @dev ERC20基本变量
    // 地址到余额的映射
    mapping(address => uint256) private _balances;
    // 地址到授权额度的映射（授权者=>被授权者=>额度）
    mapping(address => mapping(address => uint256)) private _allowances;

    // @dev 冻结和暂停功能的变量
    mapping(address => bool) private _frozen; // 地址冻结状态（地址=>是否冻结）
    mapping(address => uint256) private _frozenAmounts; // 地址冻结金额（地址=>冻结的代币数量）

    uint256 private _totalSupply; // 总供应量

    // @dev 代币信息
    string private _name; // 代币名称
    string private _symbol; // 代币符号
    uint8 private immutable _decimals; // 小数位数（不可变）
    address private _onchainID; // 链上ID地址
    string private constant _TOKEN_VERSION = "RAPTOR-5.0.0"; // 代币版本

    // keccak256(AGENT_ROLE)的哈希结果
    bytes32 public constant AGENT_ROLE = 0xcab5a0bfe0b79d2c4b1c2e02599fa044d115b7511f9659307cb4276950967709;

    // keccak256(OWNER_ROLE)的哈希结果
    bytes32 public constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;

    // @dev 链上验证器系统使用的身份注册表合约
    IIdentityRegistry private _identityRegistry;

    // @dev 与链上验证器系统关联的合规合约
    ICompliance private _compliance;

    // @dev 构造函数初始化代币合约
    // _msgSender()自动被设置为智能合约的所有者
    // @param identityRegistry_ 与代币关联的身份注册表地址
    // @param compliance_ 与代币关联的合规合约地址
    // @param name_ 代币名称
    // @param symbol_ 代币符号
    // @param decimals_ 代币小数位数
    // @param onchainID_ 代币的链上ID地址
    // 触发`UpdatedTokenInformation`事件
    // 触发`IdentityRegistryAdded`事件
    // 触发`ComplianceAdded`事件
    constructor(
        address identityRegistry_,
        address compliance_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address onchainID_
    ) {
        require(
            identityRegistry_ != address(0) && compliance_ != address(0),
            unicode"ERC-3643: 无效的零地址"
        );

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _onchainID = onchainID_;

        _grantRole(bytes32(0), _msgSender());
        _grantRole(OWNER_ROLE, _msgSender());
        _grantRole(AGENT_ROLE, _msgSender());

        _identityRegistry = IIdentityRegistry(identityRegistry_);
        _compliance = ICompliance(compliance_);
        _compliance.bindToken(address(this));

        emit IdentityRegistryAdded(identityRegistry_);
        emit ComplianceAdded(compliance_);
        emit UpdatedOnchainID(_onchainID);
    }

    // @notice 批准`spender`花费`amount`数量的代币
    // @param spender 被允许花费代币的账户地址
    // @param amount 可花费的代币数量
    // @return 表示操作是否成功的布尔值
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // @notice 包含交易有效性检查逻辑的ERC-20重写函数
    // @dev 向另一个地址转移代币。要求_msgSender()和接收地址未被冻结，且转移金额不超过可用余额
    // @param to 接收者地址
    // @param amount 要转移的代币数量
    // @return 转移成功返回true
    function transfer(
        address to,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    // @dev 包含交易有效性检查逻辑的ERC-20重写函数
    // @dev 从一个地址向另一个地址转移代币。要求`from`和`to`地址未被冻结，且转移金额不超过可用余额
    // @param from 发送者地址
    // @param to 接收者地址
    // @param amount 要转移的代币数量
    // @return 转移成功返回true
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        _transfer(from, to, amount);

        return true;
    }

    // @notice 增加调用者授予`spender`的额度
    // @param spender 被允许花费代币的账户地址
    // @param _addedValue 增加的额度
    // @return 表示操作是否成功的布尔值
    function increaseAllowance(
        address spender,
        uint256 _addedValue
    ) external returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (_addedValue)
        );
        return true;
    }

    // @notice 减少调用者授予`spender`的额度
    // @param spender 被允许花费代币的账户地址
    // @param _subtractedValue 减少的额度
    // @return 表示操作是否成功的布尔值
    function decreaseAllowance(
        address spender,
        uint256 _subtractedValue
    ) external returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - _subtractedValue
        );
        return true;
    }

    // @dev 设置代币的链上ID。仅可由合约所有者调用
    // @param onchainID_ 链上ID的地址
    // @notice 触发UpdatedOnchainID事件
    function setOnchainID(address onchainID_) external onlyRole(OWNER_ROLE) {
        _onchainID = onchainID_;
        emit UpdatedOnchainID(onchainID_);
    }

    // @notice 暂停所有代币操作
    // @dev 仅可由合约代理调用
    function pause() external onlyRole(AGENT_ROLE) {
        _pause();
    }

    // @notice 解除所有代币操作的暂停状态
    // @dev 仅可由合约代理调用
    function unpause() external onlyRole(AGENT_ROLE) {
        _unpause();
    }

    // @dev 执行代币的批量转移
    // @param toList 接收者地址数组
    // @param amounts 要转移的金额数组
    function batchTransfer(
        address[] calldata toList,
        uint256[] calldata amounts
    ) external whenNotPaused {
        uint length = toList.length;
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _transfer(_msgSender(), toList[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 执行代币的批量授权转移
    // @param fromList 发送者地址数组
    // @param toList 接收者地址数组
    // @param amounts 要转移的金额数组
    function batchTransferFrom(
        address[] calldata fromList,
        address[] calldata toList,
        uint256[] calldata amounts
    ) external whenNotPaused {
        uint length = fromList.length;
        require(length == toList.length, unicode"ERC-3643: 数组长度不匹配");
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _spendAllowance(fromList[i], _msgSender(), amounts[i]);
            _transfer(fromList[i], toList[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 执行代币的批量强制转移
    // @param fromList 发送者地址数组
    // @param toList 接收者地址数组
    // @param amounts 要转移的金额数组
    function batchForcedTransfer(
        address[] calldata fromList,
        address[] calldata toList,
        uint256[] calldata amounts
    ) external onlyRole(AGENT_ROLE) {
        uint length = fromList.length;
        require(length == toList.length, unicode"ERC-3643: 数组长度不匹配");
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _forcedTransfer(fromList[i], toList[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 执行代币的批量铸造
    // @param toList 接收者地址数组
    // @param amounts 要铸造的金额数组
    function batchMint(
        address[] calldata toList,
        uint256[] calldata amounts
    ) external onlyRole(AGENT_ROLE) {
        uint length = toList.length;
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _mint(toList[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 执行代币的批量销毁
    // @param accounts 要从中销毁代币的地址数组
    // @param amounts 要销毁的金额数组
    function batchBurn(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(AGENT_ROLE) {
        uint length = accounts.length;
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _burn(accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 执行地址的批量冻结/解冻
    // @param accounts 要冻结的地址数组
    // @param freeze 指示是否冻结对应地址的布尔值数组
    function batchSetAddressFrozen(
        address[] calldata accounts,
        bool[] calldata freeze
    ) external onlyRole(AGENT_ROLE) {
        uint length = accounts.length;
        require(length == freeze.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _setAddressFrozen(accounts[i], freeze[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 从多个地址批量冻结部分代币
    // @param accounts 要从中冻结代币的地址数组
    // @param amounts 要冻结的金额数组
    function batchFreezePartialTokens(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(AGENT_ROLE) {
        uint length = accounts.length;
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _freezePartialTokens(accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 从多个地址批量解冻部分代币
    // @param accounts 要从中解冻代币的地址数组
    // @param amounts 要解冻的金额数组
    function batchUnfreezePartialTokens(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyRole(AGENT_ROLE) {
        uint length = accounts.length;
        require(length == amounts.length, unicode"ERC-3643: 数组长度不匹配");

        for (uint256 i = 0; i < length;) {
            _unfreezePartialTokens(accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    // @dev 从丢失的钱包恢复代币并转移到新钱包。仅可由合约代理调用
    // @param lostWallet 丢失的钱包地址
    // @param newWallet 新钱包地址
    // @param investorOnchainID 投资者的链上ID
    // @return 恢复成功返回true
    function recoveryAddress(
        address lostWallet,
        address newWallet,
        address investorOnchainID
    ) external onlyRole(AGENT_ROLE) returns (bool) {
        uint256 investorBalance = _balances[lostWallet];
        require(investorBalance != 0, unicode"ERC-3643: 没有可恢复的代币");

        IIdentity identity = IIdentity(investorOnchainID);

        bool isLostWalletFrozen = _frozen[lostWallet];
        bytes32 _key = keccak256(abi.encode(newWallet));

        require(
            identity.keyHasPurpose(_key, 1),
            unicode"ERC-3643: 无法恢复"
        );
        uint256 frozenTokens = _frozenAmounts[lostWallet];

        _identityRegistry.registerIdentity(
            newWallet,
            identity,
            _identityRegistry.investorCountry(lostWallet)
        );

        if (isLostWalletFrozen) _frozen[lostWallet] = false;

        _forcedTransfer(lostWallet, newWallet, investorBalance);

        if (frozenTokens != 0) {
            _freezePartialTokens(newWallet, frozenTokens);
        }
        if (isLostWalletFrozen == true) {
            _setAddressFrozen(newWallet, true);
        }
        _identityRegistry.deleteIdentity(lostWallet);

        emit RecoverySuccess(lostWallet, newWallet, investorOnchainID);

        return true;
    }

    // @notice 执行从一个地址到另一个地址的强制代币转移
    // @param from 代币转出的地址
    // @param to 代币转入的地址
    // @param amount 要转移的代币数量
    // @return 转移成功返回true，否则返回false
    function forcedTransfer(
        address from,
        address to,
        uint256 amount
    ) external onlyRole(AGENT_ROLE) returns (bool) {
        return _forcedTransfer(from, to, amount);
    }

    // @notice 铸造新代币并分配给指定地址
    // @param _to 将接收铸造代币的地址
    // @param amount 要铸造的代币数量
    function mint(address _to, uint256 amount) external onlyRole(AGENT_ROLE) {
        _mint(_to, amount);
    }

    // @notice 从指定地址销毁代币
    // @param account 要从中销毁代币的地址
    // @param amount 要销毁的代币数量
    function burn(
        address account,
        uint256 amount
    ) external onlyRole(AGENT_ROLE) {
        _burn(account, amount);
    }

    // @notice 冻结或解冻指定地址
    // @param account 要冻结或解冻的地址
    // @param freeze 指示冻结（true）或解冻（false）的布尔值
    function setAddressFrozen(
        address account,
        bool freeze
    ) external onlyRole(AGENT_ROLE) {
        _frozen[account] = freeze;

        emit AddressFrozen(account, freeze, _msgSender());
    }

    // @notice 冻结指定账户中的一定数量代币
    // @param account 要冻结代币的账户
    // @param amount 要冻结的代币数量
    function freezePartialTokens(
        address account,
        uint256 amount
    ) external onlyRole(AGENT_ROLE) {
        _freezePartialTokens(account, amount);
    }

    // @notice 解冻指定账户中的一定数量代币
    // @param account 要解冻代币的账户
    // @param amount 要解冻的代币数量
    function unfreezePartialTokens(
        address account,
        uint256 amount
    ) external onlyRole(AGENT_ROLE) {
        _unfreezePartialTokens(account, amount);
    }

    // @notice 设置身份注册表合约地址
    // @param newIdentityRegistry 新的身份注册表合约地址
    function setIdentityRegistry(
        address newIdentityRegistry
    ) external onlyRole(OWNER_ROLE) {
        _identityRegistry = IIdentityRegistry(newIdentityRegistry);
        emit IdentityRegistryAdded(newIdentityRegistry);
    }

    // @notice 设置合规合约地址
    // @param newCompliance 新的合规合约地址
    function setCompliance(
        address newCompliance
    ) external onlyRole(OWNER_ROLE) {
        require(newCompliance != address(0), unicode"ERC-3643: 无效的零地址");

        _compliance.unbindToken(address(this));
        _compliance = ICompliance(newCompliance);
        _compliance.bindToken(address(this));
        emit ComplianceAdded(newCompliance);
    }

    // @dev 返回代币名称
    function name() external view returns (string memory) {
        return _name;
    }

    // @dev 返回代币符号
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    // @dev 返回代币使用的小数位数
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    // @dev 返回代币的链上ID
    function onchainID() external view returns (address) {
        return _onchainID;
    }

    // @notice 获取指定账户的余额
    // @param account 账户地址
    // @return uint256 指定账户的余额
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // @dev 返回代币的总供应量
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // @dev 返回所有者授予花费者的代币额度
    // @param owner 所有者地址
    // @param spender 花费者地址
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    // @dev 返回地址是否被冻结
    // @param account 要检查的地址
    function isFrozen(address account) external view returns (bool) {
        return _frozen[account];
    }

    // @dev 返回地址的冻结代币数量
    // @param account 要检查的地址
    function getFrozenTokens(address account) external view returns (uint256) {
        return _frozenAmounts[account];
    }

    // @dev 返回与代币关联的当前合规合约
    function compliance() external view returns (address) {
        return address(_compliance);
    }

    // @dev 返回与代币关联的当前身份注册表合约
    function identityRegistry() external view returns (IIdentityRegistry) {
        return _identityRegistry;
    }

    // @dev 返回代币版本
    function version() external pure returns (string memory) {
        return _TOKEN_VERSION;
    }

    // @notice 包含交易有效性检查逻辑的ERC-20重写函数
    // 要求`from`和`to`地址未被冻结
    // 要求`amount`不超过可用余额
    // 要求`to`地址是已验证地址
    // @param from 发送者地址
    // @param to 接收者地址
    // @param amount 要转移的代币数量
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), unicode"ERC-3643: 从 zero 地址转移");
        require(to != address(0), unicode"ERC-3643: 向 zero 地址转移");

        require(!_frozen[to] && !_frozen[from], unicode"ERC-3643: 钱包已冻结");
        uint256 fromBalance = _balances[from];

        require(fromBalance >= amount, unicode"ERC-3643: 金额超过余额");
        require(
            amount <= fromBalance - (_frozenAmounts[from]),
            unicode"ERC-3643: 余额被冻结"
        );

        require(
            _identityRegistry.isVerified(to),
            unicode"ERC-3643: 身份未验证"
        );
        require(
            _compliance.canTransfer(from, to, amount),
            unicode"ERC-3643: 合规检查失败"
        );

        unchecked {
            _balances[from] = fromBalance - amount;
        // 溢出不可能：所有余额的总和受总供应量限制，通过先减后增保持总和不变
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
        _compliance.transferred(_msgSender(), to, amount);
    }

    // @dev 向`account`铸造一定数量的代币
    // @param account 接收者地址
    // @param amount 要铸造的代币数量
    function _mint(address account, uint256 amount) private {
        require(account != address(0), unicode"ERC-3643: 向 zero 地址铸造");
        require(
            _identityRegistry.isVerified(account),
            unicode"ERC-3643: 身份未验证"
        );
        require(
            _compliance.canTransfer(address(0), account, amount),
            unicode"ERC-3643: 合规检查失败"
        );

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
        _compliance.created(account, amount);
    }

    // @dev 从发送者账户销毁一定数量的代币
    // @param account 发送者地址
    // @param amount 要销毁的代币数量
    function _burn(address account, uint256 amount) private {
        require(account != address(0), unicode"ERC-3643: 从 zero 地址销毁");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, unicode"ERC-3643: 销毁金额超过余额");

        uint256 freeBalance = accountBalance - _frozenAmounts[account];
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenAmounts[account] =
                _frozenAmounts[account] -
                (tokensToUnfreeze);
            emit TokensUnfrozen(account, tokensToUnfreeze);
        }
        unchecked {
            _balances[account] = accountBalance - amount;
        // 溢出不可能：金额 <= 账户余额 <= 总供应量
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
        _compliance.destroyed(account, amount);
    }

    // @notice 批准指定额度给花费者
    // @dev 批准指定额度给花费者的私有函数
    // 触发Approval事件
    // @param owner 所有者地址
    // @param spender 花费者地址
    // @param amount 批准的额度
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), unicode"ERC-3643: 从 zero 地址批准");
        require(spender != address(0), unicode"ERC-3643: 向 zero 地址批准");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // @notice 从一个地址向另一个地址强制转移指定数量的代币
    // @dev 从一个地址向另一个地址转移代币的私有函数
    // 要求`from`地址有足够的余额。必要时调整冻结代币
    // @param from 转出地址
    // @param to 转入地址
    // @param amount 转移数量
    // @return 强制转移成功返回true
    function _forcedTransfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        uint fromBalance = _balances[from];

        require(fromBalance >= amount, unicode"ERC-3643: 发送者余额不足");
        uint256 freeBalance = fromBalance - (_frozenAmounts[from]);
        if (amount > freeBalance) {
            uint256 tokensToUnfreeze = amount - (freeBalance);
            _frozenAmounts[from] = _frozenAmounts[from] - (tokensToUnfreeze);
            emit TokensUnfrozen(from, tokensToUnfreeze);
        }
        _transfer(from, to, amount);
        return true;
    }

    // @dev 减少发送者授予花费者的代币额度
    // @param owner 发送者地址
    // @param spender 花费者地址
    // @param amount 要减少的授权额度
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        uint256 currentAllowance = _allowances[owner][spender];

        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                unicode"ERC3643: 授权额度不足"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    // @dev 冻结或解冻账户
    // @param account 账户地址
    // @param freeze 冻结或解冻账户的布尔值
    function _setAddressFrozen(address account, bool freeze) private {
        _frozen[account] = freeze;

        emit AddressFrozen(account, freeze, _msgSender());
    }

    // @dev 冻结账户中的一定数量代币
    // @param account 账户地址
    // @param amount 要冻结的代币数量
    function _freezePartialTokens(address account, uint256 amount) private {
        uint256 balance = _balances[account];
        require(
            balance >= _frozenAmounts[account] + amount,
            unicode"金额超过可用余额"
        );
        _frozenAmounts[account] = _frozenAmounts[account] + (amount);
        emit TokensFrozen(account, amount);
    }

    // @dev 解冻账户中的一定数量代币
    // @param account 账户地址
    // @param amount 要解冻的代币数量
    function _unfreezePartialTokens(address account, uint256 amount) private {
        require(
            _frozenAmounts[account] >= amount,
            unicode"金额应小于或等于冻结代币数量"
        );
        unchecked {
            _frozenAmounts[account] = _frozenAmounts[account] - (amount);
        }
        emit TokensUnfrozen(account, amount);
    }
}
