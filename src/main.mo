import Array "mo:base/Array";
import Time "mo:base/Time";
import Types "./types";
import HashMap "mo:base/HashMap";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Timer "mo:base/Timer";
import Principal "mo:base/Principal";

actor Ballot {

    type Ballot = Types.Ballot;
    type Result<Ok, Err> = Types.Result<Ok, Err>;
    type Option = Types.Option;
    type ProposalStatus = Types.ProposalStatus;
    type PublicBallot = Types.PublicBallot;
    type Buffer<T> = Buffer.Buffer<T>;

    var nextBallotId : Nat64 = 0;
    var allowedPrincipals : [Principal] = [];
    let ballots = HashMap.HashMap<Nat64, Ballot>(0, Nat64.equal, Nat64.toNat32);

    let community_board : Types.CommunityBoard =  actor("q3gy3-sqaaa-aaaas-aaajq-cai");

    public shared ({caller}) func reboot_ballot_addProposal(allOptions : [Text], durationSecs : Nat) : async Result<Nat64, Text> {
        if (not isAllowed(caller)) {
            return #err("Not allowed to create a proposal.");
        };
        let options = HashMap.HashMap<Nat64, Option>(0, Nat64.equal, Nat64.toNat32);

        var currentOptionId : Nat64 = 0;
        for (optionText in Iter.fromArray(allOptions)) {
            let option : Option = {
                id = currentOptionId;
                description = optionText;
                votes = 0;
            };
            options.put(option.id, option);
            currentOptionId += 1;
        };

        let ballot : Ballot = {
            id = nextBallotId;
            options = options;
            end = Time.now() + durationSecs * 1_000_000_000;
            status = #Open;
        };
        ballots.put(nextBallotId, ballot);
        nextBallotId += 1;
        return #ok(nextBallotId - 1);
    };

    public shared ({caller}) func ballot_vote(optionId: Nat64, ballotId: Nat64) : async Result<(), Text> {
        if (not isAllowed(caller)) {
            return #err("Not allowed to vote.");
        };
        switch(ballots.get(ballotId)) {
            case (?ballot) {
                if (ballot.end > Time.now()) { // if it ended

                    let _ballot : Ballot = {
                        id = ballot.id;
                        options = ballot.options;
                        end = ballot.end;
                        status = #Closed;
                    };
                    ballots.put(_ballot.id, _ballot);
                    return #err("Ballot has already ended.");
                };
                switch(ballot.status) {
                    case (#Open) {
                        switch(ballot.options.get(optionId)) {
                            case (?opt) {
                                let option : Option = {
                                    id = opt.id;
                                    description = opt.description;
                                    votes = opt.votes + 1;
                                };
                                ballot.options.put(option.id, option);
                                return #ok();
                            };
                            case (null) {
                                return #err("Option not found.");
                            };
                        };
                    };
                    case (#Closed) {
                        return #err("Ballot has already ended.");
                    }
                };
            };
            case (null) {
                return #err("Ballot not found.");
            }
        }
    };


    public query func ballot_getBallot(ballotId: Nat64) : async Result<PublicBallot, Text> {
        let ballot = ballots.get(ballotId);
        switch(ballot) {
            case (?ballot) {
                let sharableBallot : PublicBallot = {
                    id = ballot.id;
                    options = Iter.toArray(ballot.options.vals());
                    end = ballot.end;
                    status = ballot.status;
                };
                return #ok(sharableBallot);     
            };
            case (null) {
                return #err("Ballot not found");
            };
        };
    };

    public query func ballot_getBallots() : async [PublicBallot] {
        let originalBallots : [Ballot] = Iter.toArray(ballots.vals());

        let publicBallots : [PublicBallot] = Array.map<Ballot, PublicBallot>(originalBallots, func (ballot : Ballot) : PublicBallot {
            return {
                id = ballot.id;
                options = Iter.toArray(ballot.options.vals()); 
                end = ballot.end;
                status = ballot.status;
            };
        });

        return publicBallots;
    };

    public query func ballot_getBallotOptions(ballotId: Nat64) : async Result<[Option], Text> {
        switch(ballots.get(ballotId)) {
            case (?ballot) {
                return #ok(Iter.toArray(ballot.options.vals()));
            };
            case (null) {
                return #err("Ballot not found");
            };
        };
    };

    private func isAllowed(principal : Principal) : (Bool) {
        switch(Array.indexOf<Principal>(principal, allowedPrincipals, Principal.equal) ){
            case (?index) {
                return true;
            };
            case (null) {
                return false;
            };
        };
    };

    private func setAllowedPrincipals() : async () {

        let logs = await community_board.reboot_getLogs();
        let _allowedPrincipals : Buffer<Principal> = Buffer.Buffer<Principal>(0);

        for (log in logs.vals()) {
            _allowedPrincipals.add(log.2);
        };
        allowedPrincipals := Buffer.toArray(_allowedPrincipals);
    };

    let _daily = Timer.recurringTimer<system>(#seconds (24 * 60 * 60), setAllowedPrincipals);



};
