//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Whitelist is Pausable, Ownable {
    // Max number of whitelisted addresses allowed
    uint256 public maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;

    mapping(address => bool) public bannedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    // NOTE: Don't change this variable name, as it will be part of verification
    uint8 public numAddressesWhitelisted;

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint256 _maxWhitelistedAddresses) {
        //fix max whitelist lenght.
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
        //add address to whitelist automatically
        addAddressToWhitelist();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
        addAddressToWhitelist - This function adds the address of the sender to the
        whitelist
     */
    function addAddressToWhitelist() public {
        // check if user is baned
        require(
            !bannedAddresses[msg.sender],
            "Sender has a permaban, cannot join the whitelist"
        );
        // check if the user has already been whitelisted
        require(
            !whitelistedAddresses[msg.sender],
            "Sender has already been whitelisted"
        );

        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "More addresses cant be added, limit reached"
        );
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    function banAddress(address _bannedAddress) public onlyOwner {
        whitelistedAddresses[_bannedAddress] = false;
        bannedAddresses[_bannedAddress] = true;
        numAddressesWhitelisted -= 1;
    }

    function revokeBanAddress(address _bannedAddress) public onlyOwner {
        //mod only change the mapping state, if want to be whitelisted again you have to call addAddressToWhitelist again..
        bannedAddresses[_bannedAddress] = false;
    }
}
