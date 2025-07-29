pragma solidity 0.8.17;

import "@onchain-id/solidity/contracts/interface/IClaimIssuer.sol";

interface IClaimIssuersRegistry {
    /**
     * 当一个声明发行者被添加到注册表中时发出此事件。
     * 该事件由 addClaimIssuer 函数触发。
     * `claimIssuer` 是声明发行者的 ClaimIssuer 合约地址。
     * `claimTopics` 是声明发行者被允许发出的声明集。
     */
    event ClaimIssuerAdded(
        IClaimIssuer indexed claimIssuer,
        uint256[] claimTopics
    );

    /**
     * 当一个声明发行者从注册表中移除时发出此事件。
     * 该事件由 removeClaimIssuer 函数触发。
     * `claimIssuer` 是声明发行者的 ClaimIssuer 合约地址。
     */
    event ClaimIssuerRemoved(IClaimIssuer indexed claimIssuer);

    /**
     * 当给定的声明发行者的声明主题集发生变化时发出此事件。
     * 该事件由 updateIssuerClaimTopics 函数触发。
     * `claimIssuer` 是声明发行者的 ClaimIssuer 合约地址。
     * `claimTopics` 是声明发行者被允许发出的声明集。
     */
    event ClaimTopicsUpdated(
        IClaimIssuer indexed claimIssuer,
        uint256[] claimTopics
    );

    /**
     * @dev 注册一个 ClaimIssuer 合约为声明发行者。
     * 要求不存在相同的 ClaimIssuer 合约。
     * 要求 claimTopics 集不为空。
     * 要求 claimTopics 不超过15个。
     * 要求 Claim 发行者不超过50个。
     * @param _claimIssuer 声明发行者的 ClaimIssuer 合约地址。
     * @param _claimTopics 声明发行者被允许发出的声明主题集。
     * 此函数只能由 Claim Issuers Registry 合约的所有者调用。
     * 触发 `ClaimIssuerAdded` 事件。
     */
    function addClaimIssuer(
        IClaimIssuer _claimIssuer,
        uint256[] calldata _claimTopics
    ) external;

    /**
     * @dev 移除一个声明发行者的 ClaimIssuer 合约。
     * 要求该声明发行者合约已先注册。
     * @param _claimIssuer 要移除的声明发行者。
     * 此函数只能由 Claim Issuers Registry 合约的所有者调用。
     * 触发 `ClaimIssuerRemoved` 事件。
     */
    function removeClaimIssuer(IClaimIssuer _claimIssuer) external;

    /**
     * @dev 更新声明发行者被允许发出的声明主题集。
     * 要求此 ClaimIssuer 合约已在注册表中存在。
     * 要求提供的 claimTopics 集不为空。
     * 要求 claimTopics 不超过15个。
     * @param _claimIssuer 要更新的声明发行者。
     * @param _claimTopics 声明发行者被允许发出的声明主题集。
     * 此函数只能由 Claim Issuers Registry 合约的所有者调用。
     * 触发 `ClaimTopicsUpdated` 事件。
     */
    function updateIssuerClaimTopics(
        IClaimIssuer _claimIssuer,
        uint256[] calldata _claimTopics
    ) external;

    /**
     * @dev 获取所有存储的声明发行者。
     * @return 所有注册的声明发行者数组。
     */
    function getClaimIssuers() external view returns (IClaimIssuer[] memory);

    /**
     * @dev 获取特定声明主题的所有声明发行者。
     * @param claimTopic 要获取声明发行者的声明主题。
     * @return 允许为给定声明主题发出声明的所有声明发行者地址数组。
     */
    function getClaimIssuersForClaimTopic(
        uint256 claimTopic
    ) external view returns (IClaimIssuer[] memory);

    /**
     * @dev 检查 ClaimIssuer 合约是否是声明发行者。
     * @param _issuer ClaimIssuer 合约地址。
     * @return 如果发行人是声明发行者，则返回 true，否则返回 false。
     */
    function isClaimIssuer(IClaimIssuer _issuer) external view returns (bool);

    /**
     * @dev 获取声明发行者允许发出的所有声明主题。
     * 要求提供的 ClaimIssuer 合约已在声明发行者注册表中注册。
     * @param _claimIssuer 相关的声明发行者。
     * @return 声明发行者被允许发出的声明主题集。
     */
    function getClaimIssuerClaimTopics(
        IClaimIssuer _claimIssuer
    ) external view returns (uint256[] memory);

    /**
     * @dev 检查声明发行者是否被允许发出某个声明主题。
     * @param _issuer 声明发行者的 ClaimIssuer 合约地址。
     * @param _claimTopic 要检查的声明主题，以确定 `issuer` 是否被允许发出它。
     * @return 如果发行人对于这个声明主题是声明发行者，则返回 true。
     */
    function hasClaimTopic(
        IClaimIssuer _issuer,
        uint256 _claimTopic
    ) external view returns (bool);
}