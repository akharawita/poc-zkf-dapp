// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZKFToken} from "../src/ZKFToken.sol";

contract ZKFTokenTest is Test {
    ZKFToken public token;

    address alice = vm.addr(1);
    address bob = vm.addr(2);

    uint256 tokenId = 1;
    uint256 amount = 100;

    function setUp() public {
        token = new ZKFToken();
    }

    function test_balanceOf() public {
        token.mint(alice, tokenId, 1);

        assertEq(token.balanceOf(alice, tokenId), 1);
        assertEq(token.balanceOf(bob, tokenId), 0);
    }

    function test_transfer() public {
        token.mint(alice, tokenId, 1);

        assertEq(token.balanceOf(alice, tokenId), 1);
        assertEq(token.balanceOf(bob, tokenId), 0);

        vm.prank(alice);
        token.transfer(bob, tokenId, 1);

        assertEq(token.balanceOf(alice, tokenId), 0);
        assertEq(token.balanceOf(bob, tokenId), 1);
    }

    function test_transferFrom() public {
        token.mint(alice, tokenId, 1);

        assertEq(token.balanceOf(alice, tokenId), 1);
        assertEq(token.balanceOf(bob, tokenId), 0);

        vm.prank(alice);
        token.approve(bob, tokenId, 1);

        vm.prank(bob);
        token.transferFrom(alice, bob, tokenId, 1);

        assertEq(token.balanceOf(alice, tokenId), 0);
        assertEq(token.balanceOf(bob, tokenId), 1);
    }
}
