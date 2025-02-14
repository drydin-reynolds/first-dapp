// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JobBoard {
    enum JobStatus { Active, Fulfilled, Ghosted }
    
    struct Application {
        address candidate;
        uint256 appliedAt;
        uint256 interviewConfirmedAt;
        bool interviewCompleted;
    }

    struct Job {
        address employer;
        uint256 stake;
        JobStatus status;
        uint256 totalCandidates;
        uint256 createdAt;
        uint256 interviewExpiryDays;
        mapping(uint256 => Application) applications;
    }

    IERC20 public immutable token;
    uint256 public jobCounter;
    mapping(uint256 => Job) public jobs;
    uint256 public constant INTERVIEW_EXPIRY_DEFAULT = 14 days;

    event JobCreated(uint256 jobId, address employer, uint256 stake);
    event JobApplied(uint256 jobId, address candidate);
    event InterviewConfirmed(uint256 jobId, address candidate);
    event GhostSlashed(uint256 jobId, uint256 slashedAmount);
    event JobFulfilled(uint256 jobId);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function createJobListing(uint256 stakeAmount) external {
        require(stakeAmount > 0, "Stake required");
        require(
            token.allowance(msg.sender, address(this)) >= stakeAmount,
            "Insufficient allowance"
        );
        require(
            token.transferFrom(msg.sender, address(this), stakeAmount),
            "Transfer failed"
        );

        jobCounter++;
        Job storage newJob = jobs[jobCounter];
        newJob.employer = msg.sender;
        newJob.stake = stakeAmount;
        newJob.status = JobStatus.Active;
        newJob.createdAt = block.timestamp;
        newJob.interviewExpiryDays = INTERVIEW_EXPIRY_DEFAULT;

        emit JobCreated(jobCounter, msg.sender, stakeAmount);
    }

    function applyForJob(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Active, "Job not active");
        
        Application storage app = job.applications[job.totalCandidates];
        app.candidate = msg.sender;
        app.appliedAt = block.timestamp;
        
        job.totalCandidates++;
        emit JobApplied(jobId, msg.sender);
    }

    function confirmInterview(uint256 jobId, uint256 applicationId) external {
        Job storage job = jobs[jobId];
        Application storage app = job.applications[applicationId];
        
        require(app.candidate == msg.sender, "Not applicant");
        require(app.interviewConfirmedAt == 0, "Already confirmed");
        
        app.interviewConfirmedAt = block.timestamp;
        emit InterviewConfirmed(jobId, msg.sender);
    }

    function flagAsGhostListing(uint256 jobId) external {
        Job storage job = jobs[jobId];
        require(job.status == JobStatus.Active, "Invalid status");
        require(
            block.timestamp > job.createdAt + job.interviewExpiryDays,
            "Interview period active"
        );

        uint256 unverifiedCount = job.totalCandidates - getConfirmedCount(jobId);
        require(
            unverifiedCount >= job.totalCandidates / 2,
            "Insufficient unverified candidates"
        );
        
        _slashJob(jobId, job);
    }

    function getJobStatus(uint256 jobId) public view returns (JobStatus) {
        return jobs[jobId].status;
    }

    function getJobDetails(uint256 jobId) public view returns (
        address employer,
        uint256 stake,
        uint256 totalCandidates,
        uint256 confirmedInterviews,
        uint256 createdAt,
        uint256 expiryTimestamp
    ) {
        Job storage job = jobs[jobId];
        return (
            job.employer,
            job.stake,
            job.totalCandidates,
            getConfirmedCount(jobId),
            job.createdAt,
            job.createdAt + job.interviewExpiryDays
        );
    }

    function getConfirmedCount(uint256 jobId) public view returns (uint256) {
        Job storage job = jobs[jobId];
        uint256 count;
        for(uint256 i = 0; i < job.totalCandidates; i++) {
            if(job.applications[i].interviewConfirmedAt > 0) {
                count++;
            }
        }
        return count;
    }

    function _slashJob(uint256 jobId, Job storage job) internal {
        job.status = JobStatus.Ghosted;
        uint256 stakeAmount = job.stake;
        uint256 perCandidate = stakeAmount / job.totalCandidates;

        token.transfer(job.employer, stakeAmount / 10); // 10% penalty remains
        for(uint256 i = 0; i < job.totalCandidates; i++) {
            token.transfer(job.applications[i].candidate, perCandidate);
        }

        emit GhostSlashed(jobId, stakeAmount - (stakeAmount / 10));
    }
}
