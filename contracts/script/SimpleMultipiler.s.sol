// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PlonkVerifier} from "../src/Verifier.sol";
import {SimpleMultiplier} from "../src/SimpleMultipiler.sol";

contract SimpleMultiplierScript is Script {
    PlonkVerifier public verifier;
    SimpleMultiplier public simpleMultiplier;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        verifier = new PlonkVerifier();
        simpleMultiplier = new SimpleMultiplier(address(verifier));

        vm.stopBroadcast();
    }
}
