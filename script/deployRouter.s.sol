pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import {UniswapV2Factory} from "src/uniswap/UniswapV2Factory.sol";
import {PairFactory} from "src/velodrome/factories/PairFactory.sol";
import {TestERC20} from "src/testERC20.sol";
import {Router} from "src/router.sol";

contract DeployRouterScript is Script {
    uint STARTING_BALANCE = 10000000000000000000 ether;

    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        TestERC20 testToken1 = new TestERC20(
            "test1",
            "T1",
            18,
            STARTING_BALANCE
        );
        TestERC20 testToken2 = new TestERC20(
            "test2",
            "T2",
            18,
            STARTING_BALANCE
        );
        TestERC20 testToken3 = new TestERC20(
            "test3",
            "T3",
            6,
            STARTING_BALANCE
        );

        TestERC20 testToken4 = new TestERC20(
            "test4",
            "T4",
            6,
            STARTING_BALANCE
        );
        UniswapV2Factory uniswapFactory = new UniswapV2Factory(msg.sender);
        PairFactory velodromeFactory = new PairFactory();
        Router router = new Router(address(uniswapFactory), address(velodromeFactory));
        vm.stopBroadcast();
        console.log("t1: ", address(testToken1));
        console.log("t2: ", address(testToken2));
        console.log("t3: ", address(testToken3));
        console.log("t4: ", address(testToken4));
        console.log("uniswap factory: ", address(uniswapFactory));
        console.log("velodrome factory: ", address(velodromeFactory));
        console.log("router: ", address(router));
    }
}
