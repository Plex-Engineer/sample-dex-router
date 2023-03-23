// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "forge-std/Script.sol";

/**
 * @title   CSV Writer Helper Contract
 * @author  Plex Labs
 * @dev     All functions rely on forge-std/Script.sol to access vm cheats
 * @notice  This contract is used for writing and formatting data for csv files
 */
abstract contract CSVWriter is Script {
    /**
     * @notice  Writes data to the csv filepath given
     * @dev     If the filepath does not exist, a new path will be created
     * @param   _filepath  Filepath for the csv to write to
     * @param   _data  Data to be written to the next line of the csv
     */
    function writeToCSV(string memory _filepath, string memory _data) public {
        vm.writeLine(_filepath, _data);
    }

    /**
     * @notice  Converts uint data into a string
     * @param   _data  uint to be converted into a string
     * @return  _intString  string representation of _data
     */
    function convertUintToString(uint256 _data)
        public
        pure
        returns (string memory _intString)
    {
        _intString = vm.toString(_data);
    }

    function concatStrings(string memory a, string memory b)
        public
        pure
        returns (string memory _concatString)
    {
        _concatString = string(abi.encodePacked(a, b));
    }

    /**
     * @notice  Converts array of strings into csv line format
     * @dev     Concats all strings with "," in between each index
     * @param   _stringArray  Array of strings to be converting into one single string
     * @return  _csvLine  Output of string array ("string1,string2,...")
     */
    function convertArrayOfStringsToCSVLine(string[] memory _stringArray)
        public
        pure
        returns (string memory _csvLine)
    {
        bytes memory output;
        for (uint256 i; i < _stringArray.length; i++) {
            output = abi.encodePacked(
                output,
                _stringArray[i],
                i == _stringArray.length - 1 ? "" : ","
            );
        }
        _csvLine = string(output);
    }
}
