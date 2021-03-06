import ballerina/grpc;
import ballerina/io;
import ballerina/runtime;

string response = "";
int total = 0;
function testClientStreaming (string[] args) returns (string) {
    // Client endpoint configuration
    endpoint helloWorldClient helloWorldEp {
        host:"localhost",
        port:9090
    };

    endpoint grpc:Client ep;
    // Executing unary non-blocking call registering server message listener.
    var res = helloWorldEp -> LotsOfGreetings(typeof helloWorldMessageListener);
    match res {
        grpc:error err => {
            io:print("error");
        }
        grpc:Client con => {
            ep = con;
        }
    }

    io:print("Initialized connection sucessfully.");

    foreach greet in args {
        io:print("send greeting: " + greet);
        grpc:ConnectorError connErr = ep -> send(greet);
        if (connErr != null) {
            io:println("Error at LotsOfGreetings : " + connErr.message);
        }
    }
    _ = ep -> complete();

    int wait = 0;
    while(total < 1) {
        runtime:sleepCurrentWorker(1000);
        io:println("msg count: " + total);
        if (wait > 10) {
            break;
        }
        wait++;
    }
    io:println("completed successfully");
    return response;
}

// Server Message Listener.
service<grpc:Listener> helloWorldMessageListener {

    // Resource registered to receive server messages
    onMessage (string message) {
        response = untaint message;
        io:println("Response received from server: " + message);
        total = 1;
    }

    // Resource registered to receive server error messages
    onError (grpc:ServerError err) {
        if (err != null) {
            io:println("Error reported from server: " + err.message);
        }
    }

    // Resource registered to receive server completed message.
    onComplete () {
        total = 1;
        io:println("Server Complete Sending Responses.");
    }
}

// Non-blocking client
struct helloWorldStub {
    grpc:Client clientEndpoint;
    grpc:ServiceStub serviceStub;
}

function <helloWorldStub stub> initStub (grpc:Client clientEndpoint) {
    grpc:ServiceStub navStub = {};
    navStub.initStub(clientEndpoint, "non-blocking", descriptorKey, descriptorMap);
    stub.serviceStub = navStub;
}

function <helloWorldStub stub> LotsOfGreetings (typedesc listener) returns (grpc:Client|error) {
    var res = stub.serviceStub.streamingExecute("helloWorld/LotsOfGreetings", listener);
    match res {
        grpc:ConnectorError err => {
            error e = {message:err.message};
            return e;
        }
        grpc:Client con => {
            return con;
        }
    }
}

// Non-blocking client endpoint
public struct helloWorldClient {
    grpc:Client client;
    helloWorldStub stub;
}

public function <helloWorldClient ep> init (grpc:ClientEndpointConfiguration config) {
    // initialize client endpoint.
    grpc:Client client = {};
    client.init(config);
    ep.client = client;
    // initialize service stub.
    helloWorldStub stub = {};
    stub.initStub(client);
    ep.stub = stub;
}

public function <helloWorldClient ep> getClient () returns (helloWorldStub) {
    return ep.stub;
}

const string descriptorKey = "helloWorld.proto";
map descriptorMap =
{
    "helloWorld.proto":"0A1068656C6C6F576F726C642E70726F746F1A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F325D0A0A68656C6C6F576F726C64124F0A0F4C6F74734F664772656574696E6773121B676F6F676C652E70726F746F6275662E537472696E6756616C75651A1B676F6F676C652E70726F746F6275662E537472696E6756616C756528013000620670726F746F33",
    "google.protobuf.google/protobuf/wrappers.proto":"0A1E676F6F676C652F70726F746F6275662F77726170706572732E70726F746F120F676F6F676C652E70726F746F627566221C0A0B446F75626C6556616C7565120D0A0576616C7565180120012801221B0A0A466C6F617456616C7565120D0A0576616C7565180120012802221B0A0A496E74363456616C7565120D0A0576616C7565180120012803221C0A0B55496E74363456616C7565120D0A0576616C7565180120012804221B0A0A496E74333256616C7565120D0A0576616C7565180120012805221C0A0B55496E74333256616C7565120D0A0576616C756518012001280D221A0A09426F6F6C56616C7565120D0A0576616C7565180120012808221C0A0B537472696E6756616C7565120D0A0576616C7565180120012809221B0A0A427974657356616C7565120D0A0576616C756518012001280C427C0A13636F6D2E676F6F676C652E70726F746F627566420D577261707065727350726F746F50015A2A6769746875622E636F6D2F676F6C616E672F70726F746F6275662F7074797065732F7772617070657273F80101A20203475042AA021E476F6F676C652E50726F746F6275662E57656C6C4B6E6F776E5479706573620670726F746F33"
};

