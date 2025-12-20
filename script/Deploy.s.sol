// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {NFTMarketplace} from "../src/NFTMarketplace.sol";
import {ITrophyManager} from "../src/interfaces/ITrophyManager.sol";

contract DeployTask is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address trophyManagerAddr = vm.envAddress("TROPHY_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy
        NFTMarketplace marketplace = new NFTMarketplace();
        console.log("Deployed at:", address(marketplace));

        // 2. Submit ke Trophy Manager
        ITrophyManager(trophyManagerAddr).submitHomework(address(marketplace));

        vm.stopBroadcast();
    }
}
