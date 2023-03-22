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

    //add liquidity 
    function addLiquidity(address tokenA, address tokenB, uint amtA, uint amtB, uint slippageRatio) public returns (uint) {
        // which pool?
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(tokenA, tokenB));
        if (address(pair) == address(0)) {
            //create pair
            pair = IUniswapV2Pair(factory.createPair(tokenA, tokenB));
        } else {
            // getReserves
            (uint112 reserveA, uint112 reserveB, ) = pair.getReserves();
            
            // if abs( amtA/amtB - realReserveRatio ) > slippageRatio, revert
            uint userRatio = amtA * 1e18 / amtB;
            uint realRatio = reserveA * 1e18 / reserveB;
            uint delta = stdMath.percentDelta(userRatio, realRatio);
            require(delta > slippageRatio, "Router::addLiquidity: Slippage is too high"); 
        }

        //add liquidity to new pair
        IUniswapV2ERC20(tokenA).transferFrom(msg.sender, address(pair), amtA);
        IUniswapV2ERC20(tokenB).transferFrom(msg.sender, address(pair), amtB);

        // mint LP tokens
        return IUniswapV2Pair(pair).mint(msg.sender);


    } 

    //remove liquidity 

    //swap

    //_create pair
}