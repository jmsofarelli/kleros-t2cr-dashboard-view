/**
 *  @authors: [@jmsofarelli]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

import "./ArbitrableTokenList.sol";
import "./ArbitrableAddressList.sol";
import "./Arbitrator.sol";
import "./KlerosLiquid.sol";

/** @title DashboardView
 *  Smart Contract used to fetch data for the Token Curated List Dashboard
 */
contract DashboardView {

    /*
     *  Reduced version of a token, containing only the information needed by the dashboard ui
     */
    struct Token {
        string name;
        string ticker;
        string symbolMultihash;
    }

    /*
     * Statuses used in the Dashboard
     */
    enum Status {
        Accepted,
        Rejected,
        Pending,
        Challenged,
        Crowdfunding,
        Appealed
    }

    /**
      *  @dev Return the number of addresses by status
      *  @param _aalAddress The address of the contract ArbitrableAddressList
      *  @param _klAddress The address of the contract KlerosLiquid
      *  @param _cursor The index from where to start iteration
      *  @param _count The number of items to iterate over
      *  @return The number of addresses by status
      */
    function addressCountByStatus(address _aalAddress, address _klAddress, uint _cursor, uint _count)
        external
        view
        returns (
            uint accepted,
            uint rejected,
            uint pending,
            uint challenged,
            uint crowdfunding,
            uint appealed
        )
    {
        ArbitrableAddressList aal = ArbitrableAddressList(_aalAddress);
        KlerosLiquid kl = KlerosLiquid(_klAddress);

        for (uint i = _cursor; i < (_cursor + _count); i++) {
            address addr = aal.addressList(i);
            Status status = getAddressStatus(aal, kl, addr);
            bool wasChallenged = wasAddressChallenged(aal, addr);
            if (status == Status.Accepted) accepted++;
            if (status == Status.Rejected) rejected++;
            if (status == Status.Pending) pending++;
            if (status == Status.Crowdfunding) crowdfunding++;
            if (status == Status.Appealed) appealed++;
            if (wasChallenged) challenged++;
        }
    }

     /**
      *  @dev Return the number of tokens by status.
      *  @param _t2crAddress The address of the contract ArbitrableTokenList
      *  @param _klAddress The address of the contract KlerosLiquid
      *  @param _cursor The index from where to start iteration
      *  @param _count The number of items to iterate over
      *  @return The number of tokens by status.
      */
    function tokenCountByStatus(address _t2crAddress, address _klAddress, uint _cursor, uint _count)
        external
        view
        returns (
            uint accepted,
            uint rejected,
            uint pending,
            uint challenged,
            uint crowdfunding,
            uint appealed
        )
    {
        ArbitrableTokenList t2cr = ArbitrableTokenList(_t2crAddress);
        KlerosLiquid kl = KlerosLiquid(_klAddress);

        for (uint i = _cursor; i < (_cursor + _count); i++) {
            bytes32 tokenID = t2cr.tokensList(i);
            Status status = getTokenStatus(t2cr, kl, tokenID);
            bool wasChallenged = wasTokenChallenged(t2cr, tokenID);
            if (status == Status.Accepted) accepted++;
            if (status == Status.Rejected) rejected++;
            if (status == Status.Pending) pending++;
            if (status == Status.Crowdfunding) crowdfunding++;
            if (status == Status.Appealed) appealed++;
            if (wasChallenged) challenged++;
        }
    }

    /**
      *  @dev Return tokens whose addresses are in "Crowdfunding" status
      *  @param _aalAddress The address of the contract ArbitrableAddressList
      *  @param _t2crAddress The address of the contract ArbitrableTokenList
      *  @param _klAddress The address of the contract KlerosLiquid
      *  @param _cursor The index from where to start iteration
      *  @param _count The number of items to iterate over
      *  @return The number of tokens and the tokens themselves in "Crowdfunding" status for this iteration
      */
    function getCrowdfundingAddresses(address _aalAddress, address _t2crAddress, address _klAddress, uint _cursor, uint _count)
        external
        view
        returns ( uint count, Token[100] memory tokens )
    {
        ArbitrableAddressList aal = ArbitrableAddressList(_aalAddress);
        ArbitrableTokenList t2cr = ArbitrableTokenList(_t2crAddress);
        KlerosLiquid kl = KlerosLiquid(_klAddress);

        uint addressIndex = 0;

        for (uint i = _cursor; i < (_cursor + _count); i++) {
            address addr = aal.addressList(i);
            Status status = getAddressStatus(aal, kl, addr);
            if (status == Status.Crowdfunding) {
                Token memory token = getRegisteredToken(t2cr, addr);
                tokens[addressIndex] = token;
                addressIndex++;
            }
        }
        count = addressIndex;
    }

     /**
      *  @dev Return tokens in "Crowdfunding" status
      *  @param _t2crAddress The address of the contract ArbitrableTokenList
      *  @param _klAddress The address of the contract KlerosLiquid
      *  @param _cursor The index from where to start iteration
      *  @param _count The number of items to iterate over
      *  @return The number of tokens and tokens themselves in "Crowdfunding" status for this iteration
      */
    function getCrowdfundingTokens(address _t2crAddress, address _klAddress, uint _cursor, uint _count)
        external
        view
        returns ( uint count, Token[100] memory tokens )
    {
        ArbitrableTokenList t2cr = ArbitrableTokenList(_t2crAddress);
        KlerosLiquid kl = KlerosLiquid(_klAddress);

        uint tokenIndex = 0;

        for (uint i = _cursor; i < (_cursor + _count); i++) {
            bytes32 tokenID = t2cr.tokensList(i);
            Status status = getTokenStatus(t2cr, kl, tokenID);
            if (status == Status.Crowdfunding) {
                (string memory name, string memory ticker, , string memory symbolMultihash , , ) = t2cr.getTokenInfo(tokenID);
                tokens[tokenIndex] = Token(name, ticker, symbolMultihash);
                tokenIndex++;
            }
        }
        count = tokenIndex;
    }

     /**
      *  @dev Return the token with status "Registered" associated with the given address
      *  @param _t2cr An instance of the contract ArbitrableTokenList
      *  @param _address The address of the token
      *  @return The token with status "Registered"
      */
    function getRegisteredToken(ArbitrableTokenList _t2cr, address _address)
        internal
        view
        returns ( Token memory token )
    {
        uint tokenCount = _t2cr.tokenCount();
        for (uint i = 0; i < tokenCount; i++) {
            bytes32 tokenID = _t2cr.tokensList(i);
            (
                string memory name,
                string memory ticker,
                address addr,
                string memory symbolMultihash,
                ArbitrableTokenList.TokenStatus tokenStatus,
            ) = _t2cr.getTokenInfo(tokenID);

            if (addr == _address && tokenStatus == ArbitrableTokenList.TokenStatus.Registered) {
                return Token(name, ticker, symbolMultihash);
            }
        }
    }

    /**
     * @dev Return the status of the given address
     * @param _aal An instance of the contract ArbitrableAddressList
     * @param _kl An instance of the contract KlerosLiquid
     * @param _address The address
     * @return The status of the address
     */
    function getAddressStatus(ArbitrableAddressList _aal, KlerosLiquid _kl, address _address)
        internal
        view
        returns ( Status status )
    {
        (ArbitrableAddressList.AddressStatus addressStatus, uint numberOfRequests) = _aal.getAddressInfo(_address);

        if (addressStatus == ArbitrableAddressList.AddressStatus.Registered) {
            status = Status.Accepted;
        } else if (addressStatus == ArbitrableAddressList.AddressStatus.Absent) {
            status = Status.Rejected;
        } else if (addressStatus == ArbitrableAddressList.AddressStatus.RegistrationRequested || addressStatus == ArbitrableAddressList.AddressStatus.ClearingRequested) {
            (bool disputed, uint disputeID, , , , , , , ) = _aal.getRequestInfo(_address, numberOfRequests - 1);

            if (!disputed) {
                status = Status.Pending;
            } else {
                if (_kl.disputeStatus(disputeID) == Arbitrator.DisputeStatus.Appealable) {
                    status = Status.Crowdfunding;
                } else {
                    status = Status.Appealed;
                }
            }
        }
    }

    /**
     * @dev Return the status of the given token
     * @param _t2cr An instance of the contract ArbitrableTokenList
     * @param _kl An instance of the contract KlerosLiquid
     * @param _tokenID The ID of the token
     * @return The status of the token
     */
    function getTokenStatus(ArbitrableTokenList _t2cr, KlerosLiquid _kl, bytes32 _tokenID)
        internal
        view
        returns ( Status status )
    {
        ( , , , , ArbitrableTokenList.TokenStatus tokenStatus, uint numberOfRequests) = _t2cr.getTokenInfo(_tokenID);

        if (tokenStatus == ArbitrableTokenList.TokenStatus.Registered) {
            status = Status.Accepted;
        } else if (tokenStatus == ArbitrableTokenList.TokenStatus.Absent) {
            status = Status.Rejected;
        } else if (tokenStatus == ArbitrableTokenList.TokenStatus.RegistrationRequested || tokenStatus == ArbitrableTokenList.TokenStatus.ClearingRequested) {
            (bool disputed, uint disputeID, , , , , , , ) = _t2cr.getRequestInfo(_tokenID, numberOfRequests - 1);

            if (!disputed) {
                status = Status.Pending;
            } else {
                if (_kl.disputeStatus(disputeID) == Arbitrator.DisputeStatus.Appealable) {
                    status = Status.Crowdfunding;
                } else {
                    status = Status.Appealed;
                }
            }
        }
    }

    /**
     * @dev Check if the address was challenged at some point
     * @param _aal An instance of the contract ArbitrableAddressList
     * @param _address The address
     * @return true if the address was challenged or false if the address was not challenged
     */
    function wasAddressChallenged(ArbitrableAddressList _aal, address _address)
        internal
        view
        returns ( bool challenged )
    {
        ( , uint numberOfRequests) = _aal.getAddressInfo(_address);

        for (uint i = 0; i < numberOfRequests; i++) {
            (bool disputed, , , , , , , , ) = _aal.getRequestInfo(_address, i);

            if (disputed) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Check if the token was challenged at some point
     * @param _t2cr An instance of the contract ArbitrableTokenList
     * @param _tokenID The ID of the token
     * @return true if the token was challenged or false if the token was not challenged
     */
    function wasTokenChallenged(ArbitrableTokenList _t2cr, bytes32 _tokenID)
        internal
        view
        returns ( bool challenged )
    {
        ( , , , , , uint numberOfRequests) = _t2cr.getTokenInfo(_tokenID);

        for (uint i = 0; i < numberOfRequests; i++) {
            (bool disputed, , , , , , , , ) = _t2cr.getRequestInfo(_tokenID, i);

            if (disputed) {
                return true;
            }
        }
        return false;
    }
}