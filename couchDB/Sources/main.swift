import CouchDB
import Foundation
import Kitura
import SwiftyJSON

let router = Router()

// MARK: Database
let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false) // Couch DB port
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("polls")

// MARK: Utility functions
func createResponseForError(_ error: NSError) -> JSON {
    let status = ["status": "error", "message": error.localizedDescription]
    let result = ["result": status]
    return JSON(result)
}

// MARK: Routes

router.get("/polls/list") { request, response, next in
    defer { next() }
    // Re the completion blocks, note that Kitura is a synchronous API masking as an async one. Don't be fooled.
    // The trailing closure is really just for readability.
    database.retrieveAll(includeDocuments: true) { docs, error in
        if let error = error {
            // We're an API, so must send back JSON response
            let json = createResponseForError(error)
            response.status(.internalServerError).send(json: json)
            return
        } else {
            let status = ["status": "ok"]
            var polls = [[String: Any]]()

            if let docs = docs {
                for document in docs["rows"].arrayValue {
                    var poll = [String: Any]()
                    poll["id"] = document["id"].stringValue
                    poll["title"] = document["doc"]["title"].stringValue
                    poll["option1"] = document["doc"]["option1"].stringValue
                    poll["option2"] = document["doc"]["option2"].stringValue
                    poll["votes1"] = document["doc"]["votes1"].stringValue
                    poll["votes2"] = document["doc"]["votes2"].stringValue

                    polls.append(poll)
                }
            }

            let result: [String: Any] = ["result": status, "polls": polls]
            let json = JSON(result)
            response.status(.OK).send(json: json)
        }
    }
}

// MARK: Post new polls to OUR API.
// curl -X POST localhost:8090/polls/create -d "title=More soothing color?&option1=Green&option2=Blue"
router.post("/polls/create", middleware: BodyParser())
router.post("/polls/create") { request, response, next in
    defer { next() }

    guard let values = request.body, case .urlEncoded(let body) = values else {
        try response.status(.badRequest).end()
        return
    }

    let fields = ["title", "option1", "option2"]
    var poll = [String: Any]()
    for field in fields {
        if let value = body[field]?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            poll[field] = value
            continue
        }

        try response.status(.badRequest).end()
        return
    }

    // Finish creating the remainder of the object before we insert into CouchDB database
    poll["votes1"] = 0
    poll["votes2"] = 0
    let json = JSON(poll)
    database.create(json) { id, rev, doc, error in
        if let id = id {
            let status = ["status": "ok", "id": id]
            let result = ["result": status]
            response.status(.OK).send(json: JSON(result))
        } else {
            let errorMessage = error?.localizedDescription ?? "Unknown error"
            let status = ["status": "error", "errorMessage": errorMessage]
            let result = ["result": status]
            response.status(.internalServerError).send(json: JSON(result))
        }
    }
}

// MARK: Vote for a poll
// Use http://localhost:8090/polls/list to look up the poll IDs for all the polls, then vote for one with:
// curl -X POST localhost:8090/polls/vote/245226ca9fc3a879cece6242ff004457/2
// After the above call, verify that the vote was posted.
router.post("/polls/vote/:pollid/:option") { request, response, next in
    defer { next() }

    guard let pollIdentifier = request.parameters["pollid"], let option = request.parameters["option"] else {
        try response.status(.badRequest).end()
        return
    }

    database.retrieve(pollIdentifier) { doc, error in
        if let error = error {
            let json = createResponseForError(error)
            response.status(.forbidden).send(json: json)
            return
        } else if let doc = doc {
            let identifier = doc["_id"].stringValue
            let rev = doc["_rev"].stringValue

            var newDocument = doc
            if option == "1" {
                newDocument["votes1"].intValue += 1
            } else {
                newDocument["votes2"].intValue += 1
            }
            database.update(identifier, rev: rev, document: newDocument) { newRev, newDoc, error in
                if let error = error {
                    let status = ["status": "error"]
                    let result = ["result": status]
                    response.status(.conflict).send(json: JSON(result))
                } else {
                    let status = ["status": "ok"]
                    let result = ["result": status]
                    response.status(.OK).send(json: JSON(result))
                }
            }
        }
    }
}


// MARK: Kitura
Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

// MARK: - Curl Command HOWTOs

// When you get started, figure out the URL for your CouchDB instance. i.e. launch the admin console
// e.g. http://127.0.0.1:5984
// When running curl commands using CouchDB, you might want to make an alias to simplify the commands
// $ COUCH="localhost:5984"

// MARK: Create database
/*
 $ curl -X GET $COUCH/polls
 {"error":"not_found","reason":"Database does not exist."}

 $ curl -X PUT $COUCH/polls
 {"ok":true}
 
 $ curl -X GET $COUCH/polls
 {"db_name":"polls","update_seq":"0-g1AAAABXeJzLYWBgYMpgTmEQTM4vTc5ISXLIyU9OzMnILy7JAUklMiTV____PyuRAY-iPBYgydAApP5D1GYBAJmvHGw","sizes":{"file":8488,"external":0,"active":0},"purge_seq":0,"other":{"data_size":0},"doc_del_count":0,"doc_count":0,"disk_size":8488,"disk_format_version":6,"data_size":0,"compact_running":false,"instance_start_time":"0"}
 */

// MARK: Add data
// When trying to insert JSON data in bash, you might want to make an alias to simplify the commands
// $ JSON="Content-Type: application/json"

/*
 $ curl -X POST -H "$JSON" $COUCH/polls -d '{"title": "What color iPhone is cooler?", "option1": "Jet Black", "option2": "Rose Gold", "votes1": 0, "votes2": 0}'
 {"ok":true,"id":"245226ca9fc3a879cece6242ff003ff3","rev":"1-9b40e3a879e840d6d246588a83eb05d3"}
 $ curl -X POST -H "$JSON" $COUCH/polls -d '{"title": "Which is better: Android or iOS?", "option1": "Android", "option2": "iOS", "votes1": 0, "votes2": 0}'
 {"ok":true,"id":"245226ca9fc3a879cece6242ff0030dd","rev":"1-d4e29de380f7794b5414b9e42fc15106"}

*/

// MARK: Retrieve data
/*
 $ curl -X GET "$COUCH/polls/_all_docs" 
     is the same as
 $ curl -X GET "$COUCH/polls/_all_docs?include_docs=false"
 {"total_rows":1,"offset":0,"rows":[
 {"id":"245226ca9fc3a879cece6242ff003ff3","key":"245226ca9fc3a879cece6242ff003ff3","value":{"rev":"1-9b40e3a879e840d6d246588a83eb05d3"}}
 ]}

 $ curl -X GET "$COUCH/polls/_all_docs?include_docs=true"
 {"total_rows":1,"offset":0,"rows":[
    {"id":"245226ca9fc3a879cece6242ff003ff3",
     "key":"245226ca9fc3a879cece6242ff003ff3",
     "value":{"rev":"1-9b40e3a879e840d6d246588a83eb05d3"},
     "doc":{
        "_id":"245226ca9fc3a879cece6242ff003ff3",
        "_rev":"1-9b40e3a879e840d6d246588a83eb05d3",
        "title":"What color iPhone is cooler?",
        "option1":"Jet Black",
        "option2":"Rose Gold",
        "votes1":0,
        "votes2":0}
    }]
 }
 */
