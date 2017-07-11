/**
 * Copyright IBM Corporation 2016, 2017
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

import Foundation
import XCTest

import Kitura
import KituraNet
import KituraSession

@testable import Credentials

class TestSession : XCTestCase {

    static var allTests : [(String, (TestSession) -> () throws -> Void)] {
        return [
            ("testSession", testSession),
        ]
    }

    override func tearDown() {
        doTearDown()
    }

    let host = "127.0.0.1"

    let router = TestSession.setupRouter()
    let routerWithEmptyPath = TestSession.setupRouterWithEmptyPath()

    func testSession() {
        performServerTest(router: router) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/private/data", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, "<!DOCTYPE html><html><body><b>Dummy User is logged in with DummySession. Return to /hello.</b></body></html>\n\n")
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
                })
        }
        
        performServerTest(router: routerWithEmptyPath) { expectation in
            self.performRequest(method: "get", host: self.host, path: "/login", callback: {response in
                XCTAssertNotNil(response, "ERROR!!! ClientRequest response object was nil")
                XCTAssertEqual(response?.statusCode, HTTPStatusCode.OK, "HTTP Status code was \(String(describing: response?.statusCode))")
                do {
                    let body = try response?.readString()
                    XCTAssertEqual(body, "<!DOCTYPE html><html><body><b>Dummy User is logged in with DummySession. Return to /hello.</b></body></html>\n\n")
                }
                catch{
                    XCTFail("No response body")
                }
                expectation.fulfill()
            })
        }

    }

    static func setupRouter() -> Router {
        let router = Router()

        router.all(middleware: Session(secret: "Very very secret....."))

        let dummySessionPlugin = DummySessionPlugin(clientId: "dummyClientId", clientSecret: "dummyClientSecret", callbackUrl: "/login/callback")
        let credentials = Credentials()
        credentials.register(plugin: dummySessionPlugin)
        credentials.options["failureRedirect"] = "/login"
        credentials.options["successRedirect"] = "/private/data"

        router.all("/private/*", middleware: BodyParser())

        router.all("/private", middleware: credentials)

        router.get("/private/data") { request, response, next in
            Credentials.setRedirectingReturnTo("/hello", for: request)
            
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let profile = request.userProfile {
                    var returnToString = ""
                    if let returnTo = Credentials.getRedirectingReturnTo(for: request) {
                        returnToString = returnTo
                    }
                    try response.status(.OK).send("<!DOCTYPE html><html><body><b>\(profile.displayName) is logged in with \(profile.provider). Return to \(returnToString).</b></body></html>\n\n").end()
                }
                else {
                    try response.status(.unauthorized).end()
                }
            }
            catch {}

            next()
        }

        router.get("/login",
                   handler: credentials.authenticate(credentialsType: dummySessionPlugin.name))
        router.get("/login/callback",
                   handler: credentials.authenticate(credentialsType: dummySessionPlugin.name, failureRedirect: "/login/failure"))
        router.get("/login/failure") { _, response, next in
            do {
                try response.status(.unauthorized).end()
            }
            catch {}
            next()
        }


        router.error { request, response, next in
            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                let errorDescription: String
                if let error = response.error {
                    errorDescription = "\(error)"
                }
                else {
                    errorDescription = ""
                }
                try response.send("Caught the error: \(errorDescription)").end()
            }
            catch {}
            next()
        }
        
        return router
    }
    
    static func setupRouterWithEmptyPath() -> Router {
        let router = Router()
        
        router.all(middleware: Session(secret: "Very very secret....."))
        
        let dummySessionPlugin = DummySessionPlugin(clientId: "dummyClientId", clientSecret: "dummyClientSecret", callbackUrl: "/login/callback")
        let credentials = Credentials()
        credentials.register(plugin: dummySessionPlugin)
        
        let callbackHandler = credentials.authenticate(credentialsType: dummySessionPlugin.name, successRedirect: "/", failureRedirect: "/failure")
        router.get("/login/callback", handler: callbackHandler)
        router.get("/login", handler: credentials.authenticate(credentialsType: dummySessionPlugin.name))
        
        router.get("/") { request, response, next in
            Credentials.setRedirectingReturnTo("/hello", for: request)

            response.headers["Content-Type"] = "text/html; charset=utf-8"
            do {
                if let profile = request.userProfile {
                    var returnToString = ""
                    if let returnTo = Credentials.getRedirectingReturnTo(for: request) {
                        returnToString = returnTo
                    }
                    try response.status(.OK).send("<!DOCTYPE html><html><body><b>\(profile.displayName) is logged in with \(profile.provider). Return to \(returnToString).</b></body></html>\n\n").end()
                }
                else {
                    try response.status(.unauthorized).end()
                }
            }
            catch {}
            
            next()
        }
        
        return router
    }

}
