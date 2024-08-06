// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC6909.sol";

contract ZKFToken is ERC6909 {
    constructor() ERC6909() {}

    function mint(address receiver, uint256 id, uint256 amount) public {
        // require(msg.sender == receiver, "ZKFToken: minting to another address");
        require(amount > 0, "ZKFToken: minting zero amount");

        _mint(receiver, id, amount);
    }

    function burn(address owner, uint256 id, uint256 amount) public {
        // require(msg.sender == owner, "ZKFToken: burning from another address");
        require(amount > 0, "ZKFToken: burning zero amount");

        _burn(owner, id, amount);
    }
}
