/**
 *  @authors: [@jmsofarelli]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

interface Arbitrator { }

interface ArbitrableTokenList {

    enum TokenStatus { Absent, Registered, RegistrationRequested, ClearingRequested }
    enum Party { None, Requester, Challenger }

    function tokensList(uint index)
        external
        view
        returns ( bytes32 tokenID );

    function getTokenInfo(bytes32 _tokenID)
        external
        view
        returns (
            string memory name,
            string memory ticker,
            address addr,
            string memory symbolMultihash,
            TokenStatus status,
            uint numberOfRequests
        );

    function queryTokens(bytes32 _cursor, uint _count, bool[8] calldata _filter, bool _oldestFirst, address _tokenAddr)
        external
        view
        returns (
            bytes32[] memory values,
            bool hasMore
        );

    function getRequestInfo(bytes32 _tokenID, uint _request)
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

    function getRoundInfo(bytes32 _tokenID, uint _request, uint _round)
        external
        view
        returns (
            bool appealed,
            uint[3] memory paidFees,
            bool[3] memory hasPaid,
            uint feeRewards
        );
}

/** @title DashboardView
 *  Utility view contract to fetch requester deposit fee data
 */
contract DashboardView {

    /**
     * Type used to wrap the returned data
     */
    struct TokenDepositData {
        bytes32 ID; // ID of the token
        uint submissionTime; // Time of token submission
        uint requesterDepositFee; // Deposit fee paid by requester
    }

    /** @dev Fetch deposit data of tokens present on a Token² Curated Registry (t2cr contract)
     *  @param _t2crAddress The address of the t2cr contract
     *  @param _firstIndex The index of the first token
     *  @param _lastIndex The index of the last token
     *  @return The deposit data of the token (TokenDepositData)
     */
    function getTokensDepositData(address _t2crAddress, uint _firstIndex, uint _lastIndex)
        external
        view
        returns (TokenDepositData[] memory tokensDepositData)
    {
        ArbitrableTokenList t2cr = ArbitrableTokenList(_t2crAddress);

        // Index for tokensDepositData array
        uint tddi = 0;

        for (uint i = _firstIndex; i <= _lastIndex; i++) {
            bytes32 tokenID = t2cr.tokensList(i);

            // Get submission time
            uint submissionTime = getSubmissionTime(t2cr, tokenID);

            // Get deposit fee paid by requester
            uint requesterDepositFee = getRequesterDepositFee(t2cr, tokenID);

            // Add TokenDepositData to returned array
            tokensDepositData[tddi] = TokenDepositData(tokenID, submissionTime, requesterDepositFee);
            tddi++;
        }
    }

    /** @dev Get the submission time of the token
     * @param _t2cr An instance of the contract ArbitrableTokenList
     * @param _tokenID The ID of the token
     * @return The submission time of the token
     */
    function getSubmissionTime(ArbitrableTokenList _t2cr, bytes32 _tokenID)
        internal
        view
        returns ( uint submissionTime )
    {
        // The submission time is present in the first request (0) for the token
        ( , , submissionTime, , , , , , ) = _t2cr.getRequestInfo(_tokenID, 0);
    }

    /** @dev Get the deposit fee paid by the requester
     * @param _t2cr An instance of the contract ArbitrableTokenList
     * @param _tokenID The ID of the token
     * @return The deposit fee paid by the requester
     */
    function getRequesterDepositFee(ArbitrableTokenList _t2cr, bytes32 _tokenID)
        internal
        view
        returns ( uint requesterDepositFee )
    {
        uint[3] memory paidFees;

        // The deposit fee paid by the requester is present in the first round (0) of the first request (0) for the token
        ( , paidFees, , ) = _t2cr.getRoundInfo(_tokenID, 0, 0);
        requesterDepositFee = paidFees[1];
    }

}