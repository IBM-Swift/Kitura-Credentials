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

// MARK BaseCacheElement
import Foundation

/// The cache element for keeping user profile information.
public class BaseCacheElement {
    /// The user profile information stored as `UserProfile`.
    public var userProfile: UserProfile
    
    /// The time the UserProfile was originally created
    public var createdAt: Date
    
    /// Initialize a `BaseCacheElement`.
    ///
    /// - Parameter profile: the `UserProfile` to store.
    public init (profile: UserProfile) {
        userProfile = profile
        createdAt = Date()
    }
}

