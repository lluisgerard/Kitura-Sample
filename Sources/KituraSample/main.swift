/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

// KituraSample shows examples for creating custom routes.

import Foundation

import Kitura
//import KituraMustache

import LoggerAPI
import HeliumLogger

#if os(Linux)
    import Glibc
#endif

// All Web apps need a router to define routes
let router = Router()

// Using an implementation for a Logger
Log.logger = HeliumLogger()

/**
* RouterMiddleware can be used for intercepting requests and handling custom behavior
* such as authentication and other routing
*/
class BasicAuthMiddleware: RouterMiddleware {
    func handle(request: RouterRequest, response: RouterResponse, next: () -> Void) {
        let authString = request.headers["Authorization"]
        Log.info("Authorization: \(authString)")
        // Check authorization string in database to approve the request if fail
        // response.error = NSError(domain: "AuthFailure", code: 1, userInfo: [:])
        next()
    }
}

// Variable to post/put data to (just for sample purposes)
var name: String?

// This route executes the echo middleware
router.all(middleware: BasicAuthMiddleware())

router.all("/static", middleware: StaticFileServer())

router.get("/hello") { _, response, next in
     response.headers["Content-Type"] = "text/plain; charset=utf-8"
     let fName = name ?? "World"
     try response.send("Hello \(fName), from Kitura!").end()
}

// This route accepts POST requests
router.post("/hello") {request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    name = try request.readString()
    try response.send("Got a POST request").end()
}

// This route accepts PUT requests
router.put("/hello") {request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    name = try request.readString()
    try response.send("Got a PUT request").end()
}

// This route accepts DELETE requests
router.delete("/hello") {request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    name = nil
    try response.send("Got a DELETE request").end()
}

// Error handling example
router.get("/error") { _, response, next in
    Log.error("Example of error being set")
    response.status(.internalServerError)
    response.error = NSError(domain: "RouterTestDomain", code: 1, userInfo: [:])
    next()
}

// Redirection example
router.get("/redir") { _, response, next in
    try response.redirect("http://www.ibm.com")
    next()
}

// Reading parameters
// Accepts user as a parameter
router.get("/users/:user") { request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    let p1 = request.parameters["user"] ?? "(nil)"
    try response.send(
        "<!DOCTYPE html><html><body>" +
        "<b>User:</b> \(p1)" +
        "</body></html>\n\n").end()
}

// Uses multiple handler blocks
router.get("/multi", handler: { request, response, next in
    response.send("I'm here!\n")
    next()
}, { request, response, next in
    response.send("Me too!\n")
    next()
})
router.get("/multi") { request, response, next in
    try response.send("I come afterward..\n").end()
}

// Support for Mustache implemented for OSX only yet
//#if !os(Linux)
//router.setDefaultTemplateEngine(templateEngine: MustacheTemplateEngine())
//
//router.get("/trimmer") { _, response, next in
//    defer {
//        next()
//    }
//    // the example from https://github.com/groue/GRMustache.swift/blob/master/README.md
//    var context: [String: Any] = [
//        "name": "Arthur",
//        "date": NSDate(),
//        "realDate": NSDate().addingTimeInterval(60*60*24*3),
//        "late": true
//    ]
//
//    // Let template format dates with `{{format(...)}}`
//    let dateFormatter = NSDateFormatter()
//    dateFormatter.dateStyle = .mediumStyle
//    context["format"] = dateFormatter
//
//    try response.render("document", context: context).end()
//}
//#endif

// Handles any errors that get set
router.error { request, response, next in
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    let errorDescription: String
    if let error = response.error {
        errorDescription = "\(error)"
    } else {
        errorDescription = "Unknown error"
    }
    try response.send("Caught the error: \(errorDescription)").end()
}

// A custom Not found handler
router.all { request, response, next in
    if  response.statusCode == .unknown  {
        // Remove this wrapping if statement, if you want to handle requests to / as well
        if  request.originalURL != "/"  &&  request.originalURL != ""  {
            try response.status(.notFound).send("Route not found in Sample application!").end()
        }
    }
    next()
}

// Add HTTP Server to listen on port 8090
Kitura.addHTTPServer(onPort: 8090, with: router)

// start the framework - the servers added until now will start listening
Kitura.run()
