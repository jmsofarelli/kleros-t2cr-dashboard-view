/**
 *  @authors: [@mtsalenc]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity 0.5.10;

import "./Arbitrator.sol";

/**
 *  @title ArbitrableAddressList
 *  This contract is an arbitrable token curated registry for addresses, sometimes referred to as a Address Curated Registry. Users can send requests to register or remove addresses from the registry, which can in turn, be challenged by parties that disagree with them.
 *  A crowdsourced insurance system allows parties to contribute to arbitration fees and win rewards if the side they backed ultimately wins a dispute.
 *  NOTE: This contract trusts that the Arbitrator is honest and will not reenter or modify its costs during a call. This contract is only to be used with an arbitrator returning appealPeriod and having non-zero fees. The governor contract (which will be a DAO) is also to be trusted.
 */
interface ArbitrableAddressList {

    enum AddressStatus {
        Absent, // The address is not in the registry.
        Registered, // The address is in the registry.
        RegistrationRequested, // The address has a request to be added to the registry.
        ClearingRequested // The address has a request to be removed from the registry.
    }

    enum Party {
        None,      // Party per default when there is no challenger or requester. Also used for unconclusive ruling.
        Requester, // Party that made the request to change an address status.
        Challenger // Party that challenges the request to change an address status.
    }

    /** @dev Returns an addresses.
     *  @param index The index of the address.
     *  @return The address.
     */
    function addressList(uint index)
        external
        view
        returns (address addr);

    /** @dev Return the numbers of addresses that were submitted. Includes addresses that never made it to the list or were later removed.
     *  @return count The numbers of addresses in the list.
     */
    function addressCount()
        external
        view
        returns (uint count);

    /** @dev Return the values of the addresses the query finds. This function is O(n), where n is the number of addresses. This could exceed the gas limit, therefore this function should only be used for interface display and not by other contracts.
     *  @param _cursor The address from which to start iterating. To start from either the oldest or newest item.
     *  @param _count The number of addresses to return.
     *  @param _filter The filter to use. Each element of the array in sequence means:
     *  - Include absent addresses in result.
     *  - Include registered addresses in result.
     *  - Include addresses with registration requests that are not disputed in result.
     *  - Include addresses with clearing requests that are not disputed in result.
     *  - Include disputed addresses with registration requests in result.
     *  - Include disputed addresses with clearing requests in result.
     *  - Include addresses submitted by the caller.
     *  - Include addresses challenged by the caller.
     *  @param _oldestFirst Whether to sort from oldest to the newest item.
     *  @return The values of the addresses found and whether there are more addresses for the current filter and sort.
     */
    function queryAddresses(address _cursor, uint _count, bool[8] calldata _filter, bool _oldestFirst)
        external
        view
        returns (address[] memory values, bool hasMore);

    /** @dev Returns address information. Includes length of requests array.
     *  @param _address The queried address.
     *  @return The address information.
     */
    function getAddressInfo(address _address)
        external
        view
        returns (
            AddressStatus status,
            uint numberOfRequests
        );

    /** @dev Gets information on a request made for an address.
     *  @param _address The queried address.
     *  @param _request The request to be queried.
     *  @return The request information.
     */
    function getRequestInfo(address _address, uint _request)
        external
        view
        returns (
            bool disputed,
            uint disputeID,
            uint submissionTime,
            bool resolved,
            address[3] memory parties,
            uint numberOfRounds,
            Party ruling,
            Arbitrator arbitrator,
            bytes memory arbitratorExtraData
        );

    /** @dev Gets the information on a round of a request.
     *  @param _address The queried address.
     *  @param _request The request to be queried.
     *  @param _round The round to be queried.
     *  @return The round information.
     */
    function getRoundInfo(address _address, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            bool[3] memory hasPaid,
            uint feeRewards
        );
}