// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC6909 Multi-Token Reference Implementation
/// @author jtriley.eth
contract ERC6909 {
    /// @dev Thrown when owner balance for id is insufficient.
    /// @param owner The address of the owner.
    /// @param id The id of the token.
    error InsufficientBalance(address owner, uint256 id);

    /// @dev Thrown when spender allowance for id is insufficient.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    error InsufficientPermission(address spender, uint256 id);

    /// @notice The event emitted when a transfer occurs.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Transfer(
        address caller,
        address indexed sender,
        address indexed receiver,
        uint256 indexed id,
        uint256 amount
    );

    /// @notice The event emitted when an operator is set.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    event OperatorSet(
        address indexed owner,
        address indexed spender,
        bool approved
    );

    /// @notice The event emitted when an approval occurs.
    /// @param owner The address of the owner.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id,
        uint256 amount
    );

    /// @notice Owner balance of an id.
    mapping(address owner => mapping(uint256 id => uint256 amount))
        public balanceOf;

    /// @notice Spender allowance of an id.
    mapping(address owner => mapping(address spender => mapping(uint256 id => uint256 amount)))
        public allowance;

    /// @notice Checks if a spender is approved by an owner as an operator.
    mapping(address owner => mapping(address spender => bool))
        public isOperator;

    /// @notice Transfers an amount of an id from the caller to a receiver.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transfer(
        address receiver,
        uint256 id,
        uint256 amount
    ) public returns (bool) {
        if (balanceOf[msg.sender][id] < amount)
            revert InsufficientBalance(msg.sender, id);
        balanceOf[msg.sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, msg.sender, receiver, id, amount);
        return true;
    }

    /// @notice Transfers an amount of an id from a sender to a receiver.
    /// @param sender The address of the sender.
    /// @param receiver The address of the receiver.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function transferFrom(
        address sender,
        address receiver,
        uint256 id,
        uint256 amount
    ) public returns (bool) {
        if (sender != msg.sender && !isOperator[sender][msg.sender]) {
            uint256 senderAllowance = allowance[sender][msg.sender][id];
            if (senderAllowance < amount)
                revert InsufficientPermission(msg.sender, id);
            if (senderAllowance != type(uint256).max) {
                allowance[sender][msg.sender][id] = senderAllowance - amount;
            }
        }
        if (balanceOf[sender][id] < amount)
            revert InsufficientBalance(sender, id);
        balanceOf[sender][id] -= amount;
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, sender, receiver, id, amount);
        return true;
    }

    /// @notice Approves an amount of an id to a spender.
    /// @param spender The address of the spender.
    /// @param id The id of the token.
    /// @param amount The amount of the token.
    function approve(
        address spender,
        uint256 id,
        uint256 amount
    ) public returns (bool) {
        allowance[msg.sender][spender][id] = amount;
        emit Approval(msg.sender, spender, id, amount);
        return true;
    }

    /// @notice Sets or removes a spender as an operator for the caller.
    /// @param spender The address of the spender.
    /// @param approved The approval status.
    function setOperator(address spender, bool approved) public returns (bool) {
        isOperator[msg.sender][spender] = approved;
        emit OperatorSet(msg.sender, spender, approved);
        return true;
    }

    /// @notice Checks if a contract implements an interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return supported True if the contract implements `interfaceId`.
    function supportsInterface(
        bytes4 interfaceId
    ) public pure returns (bool supported) {
        return interfaceId == 0x0f632fb3 || interfaceId == 0x01ffc9a7;
    }

    function _mint(address receiver, uint256 id, uint256 amount) internal {
        // WARNING: important safety checks should precede calls to this method.
        balanceOf[receiver][id] += amount;
        emit Transfer(msg.sender, address(0), receiver, id, amount);
    }

    function _burn(address sender, uint256 id, uint256 amount) internal {
        // WARNING: important safety checks should precede calls to this method.
        balanceOf[sender][id] -= amount;
        emit Transfer(msg.sender, sender, address(0), id, amount);
    }
}
