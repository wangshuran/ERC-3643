// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IClaimTopicsRegistry {
    /**
     * 当一个声明主题被添加到声明主题注册表中时发出此事件。
     * 该事件由 'addClaimTopic' 函数触发。
     * `claimTopic` 是添加到声明主题注册表中的所需声明主题。
     */
    event ClaimTopicAdded(uint256 indexed claimTopic);

    /**
     *  当一个声明主题从声明主题注册表中移除时发出此事件。
     *  该事件由 'removeClaimTopic' 函数触发。
     *  `claimTopic` 是从声明主题注册表中移除的所需声明主题。
     */
    event ClaimTopicRemoved(uint256 indexed claimTopic);

    /**
     * @dev 添加一个声明主题（例如：KYC=1, AML=2）。
     * 只有合约所有者可以调用。
     * 触发 `ClaimTopicAdded` 事件。
     * 不能为单个代币添加超过15个主题，因为添加更多可能会导致 gas 问题。
     * @param _claimTopic 声明主题索引。
     */
    function addClaimTopic(uint256 _claimTopic) external;

    /**
     * @dev 移除一个声明主题（例如：KYC=1, AML=2）。
     * 只有合约所有者可以调用。
     * 触发 `ClaimTopicRemoved` 事件。
     * @param _claimTopic 声明主题索引。
     */
    function removeClaimTopic(uint256 _claimTopic) external;

    /**
     * @dev 获取安全代币的声明主题。
     * @return 声明主题数组。
     */
    function getClaimTopics() external view returns (uint256[] memory);
}
