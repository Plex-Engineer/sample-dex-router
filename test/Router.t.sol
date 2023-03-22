pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/Script.sol";
import "src/testERC20.sol";
import "src/UniswapV2Factory.sol";
import "src/router.sol";
import "src/interfaces/IUniswapV2Pair.sol";

contract SetUp is Test {
    TestERC20 testToken1;
    TestERC20 testToken2;
    UniswapV2Factory factory;
    Router router;

    address tester = address(0x1234);

    function setUp() public virtual {
        vm.startPrank(tester);
        testToken1 = new TestERC20("test1", "T1", 18);
        testToken2 = new TestERC20("test2", "T2", 18);
        factory = new UniswapV2Factory(msg.sender);
        router = new Router(address(factory));
        vm.stopPrank();
    }
}

contract RouterTest is SetUp {
    function testAddLiquidity() public {
        vm.startPrank(tester);
        testToken1.approve(address(router), 100 ether);
        testToken2.approve(address(router), 100 ether);
        uint expectedLiquidity = router.addLiquidity(
            address(testToken1),
            address(testToken2),
            50 ether,
            50 ether,
            10
        );

        address pair = factory.getPair(
            address(testToken1),
            address(testToken2)
        );
        assert(pair != address(0));
        assertEq(IUniswapV2Pair(pair).balanceOf(tester), expectedLiquidity);
    }
}
