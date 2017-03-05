import CouchDB
import Foundation
import Kitura
import SwiftyJSON

let router = Router()

// MARK: Database
let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false) // Couch DB port
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("polls")

// MARK: Routes
router.get("/polls/list") { request, response, next in
    defer { next() }
    // Re the completion blocks, note that Kitura is a synchronous API masking as an async one. Don't be fooled.
    // The trailing closure is really just for readability.
    database.retrieveAll(includeDocuments: true) { docs, error in
        if let error = error {
            // We're an API, so must send back JSON response
            let status = ["status": "error", "message": error.localizedDescription]
            let json = JSON(["result": status])
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

router.post("/polls/create") { request, response, next in
    defer { next() }
}

router.post("/polls/vote/:pollid/:option") { request, response, next in
    defer { next() }
}


// MARK: Kitura
Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

// MARK: - Curl Commands

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
