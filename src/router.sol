pragma solidity ^0.8.18;

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "forge-std/StdMath.sol";

contract Router {
    //state variables
    IUniswapV2Factory factory;

    //constructor
    constructor(address _factory) {
        factory = IUniswapV2Factory(_factory);
    }

    //methods

    /**
     * @notice  Adds liquidity to the pair with the specified token addresses
     * @dev     Creates new pair if one does not exist
     * @param   tokenA  Address of tokenA in pair
     * @param   tokenB  Address of tokenB in pair
     * @param   amtA  Amount of tokenA
     * @param   amtB  Amount of tokenB
     * @param   slippageRatio  Allowed slippage ratio to add liquidity
     * @return  uint  Amount of LP tokens recieved after adding liquidity
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amtA,
        uint amtB,
        uint slippageRatio
    ) public returns (uint) {
        require(
            tokenA != address(0),
            "Router::addLiquidity: TOKENA_ADDRESS_ZERO"
        );
        require(
            tokenB != address(0),
            "Router::addLiquidity: TOKENB_ADDRESS_ZERO"
        );
        // which pool?
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
        if (address(pair) == address(0)) {
            //create pair
            pair = IUniswapV2Pair(factory.createPair(tokenA, tokenB));
        } else {
            // getReserves
            (uint112 reserveA, uint112 reserveB, ) = pair.getReserves();

            // if abs( amtA/amtB - realReserveRatio ) > slippageRatio, revert
            uint userRatio = (amtA * 1e18) / amtB;
            uint realRatio = (uint(reserveA) * 1e18) / uint(reserveB);
            uint delta = stdMath.percentDelta(userRatio, realRatio);
            require(
                delta <= slippageRatio,
                "Router::addLiquidity: Slippage is too high"
            );
        }

        //add liquidity to new pair
        IUniswapV2ERC20(tokenA).transferFrom(msg.sender, address(pair), amtA);
        IUniswapV2ERC20(tokenB).transferFrom(msg.sender, address(pair), amtB);

        // mint LP tokens
        return IUniswapV2Pair(pair).mint(msg.sender);
    }

    //remove liquidity
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAmin,
        uint amountBmin
    ) public returns (uint amountA, uint amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
        require(
            address(pair) != address(0),
            "Router::removeLiquidity: TOKEN_ADDRESS_ZERO"
        );
        //send LP tokens to pair
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (uint amount0, uint amount1) = pair.burn(msg.sender);
        (amountA, amountB) = tokenA == pair.token0()
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAmin, "Router::removeLiquidity: INSUFFICIENT_AMOUNT_A");
        require(amountB >= amountBmin, "Router::removeLiquidity: INSUFFICIENT_AMOUNT_B");

    }

    //swap
    function swap(
        address tokenA,
        address tokenB,
        uint amtA,
        uint minAmtB
    ) public returns (uint) {
        //find pair
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
        require(
            address(pair) != address(0),
            "Router::swap: PAIR_DOES_NOT_EXIST"
        );
        //tranfer first just in case this fails
        IUniswapV2ERC20(tokenA).transferFrom(msg.sender, address(pair), amtA);
        //figure out how much of tokenB to request from pair after sending amtA
        // getReserves
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        //check the token order inside pair so we can match the values
        uint reserveA = pair.token0() == tokenA
            ? uint(reserve0)
            : uint(reserve1);
        uint reserveB = pair.token1() == tokenB
            ? uint(reserve1)
            : uint(reserve0);
        //get currentk value
        uint currentK = reserveA * reserveB;
        uint expectedReserveB = currentK / (reserveA + amtA);
        uint expectedBOut_noFee = reserveB - expectedReserveB;
        uint expectedBOut = (expectedBOut_noFee * 997) / 1000;
        require(
            expectedBOut >= minAmtB,
            "Router::removeLiquidity: EXPECTED_TOKEN_B_TOO_HIGH"
        );
        pair.swap(0, expectedBOut, msg.sender, "");
        return expectedBOut;
    }
}
