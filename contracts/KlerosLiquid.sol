pragma solidity 0.5.10;

import "./Arbitrator.sol";

interface KlerosLiquid {

    /** @dev Gets the start and end of a specified dispute's current appeal period.
     *  @param _disputeID The ID of the dispute.
     *  @return The start and end of the appeal period.
     */
    function appealPeriod(uint _disputeID)
        external
        view
        returns (
            uint start,
            uint end
        );

    /** @dev Gets the status of a specified dispute.
     *  @param _disputeID The ID of the dispute.
     *  @return The status.
     */
    function disputeStatus(uint _disputeID)
        external
        view
        returns( Arbitrator.DisputeStatus status );

}