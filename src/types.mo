import Time "mo:base/Time";
import Result "mo:base/Result";
import HashMap "mo:base/HashMap";

module {
    public type Result<Ok, Err> = Result.Result<Ok, Err>;

    public type ProposalStatus = {
        #Open;
        #Closed;
    };

    public type Option ={
        id : Nat64; // The id of the option
        description : Text; // The description of the option
        votes : Nat; // Ammount of votes for this option
    };
    
    public type Ballot = {
        id : Nat64; // The id of the ballot
        options : HashMap.HashMap<Nat64, Option>; // The options to pick from
        end : Time.Time; // The end time of the ballot
        status : ProposalStatus; // The status of the ballot
    };

    public type PublicBallot = {
        id : Nat64; // The id of the ballot
        options : [Option]; // The options to pick from
        end : Time.Time; // The end time of the ballot
        status : ProposalStatus; // The status of the ballot
    };

    public type HeaderField = (Text, Text);
    public type HttpRequest = {
        url : Text;
        method : Method;
        body : Blob;
        headers : [HeaderField];
    };
    public type HttpResponse = {
        body : Blob;
        headers : [HeaderField];
        status_code : StatusCode;
    };
    public type Method = Text;
    public type Mood = Text;
    public type Name = Text;
    public type StatusCode = Nat16;
    public type Time = Int;

    public type CommunityBoard = actor {
        http_request : shared query HttpRequest -> async HttpResponse;
        reboot_getLogs : shared query () -> async [(Name, Mood, Principal, Time)];
        reboot_writeDailyCheck : shared (Name, Mood) -> async ();
    };
};