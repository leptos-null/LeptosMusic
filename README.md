## LeptosMusic

LMusic is an iOS client for YouTube Music. It uses Google's InnerTube backend service, posing as YouTube Music. 
The [YTMProtobufs](LMYTIGeneratedProtobufs/YTMProtobufs) folder contains the Objective-C generated files of Google's Protobuf messages used in YouTube Music. 

The only information I could find about InnerTube was [this article](https://www.fastcompany.com/3044995/to-take-on-hbo-and-netflix-youtube-had-to-rewire-itself) by FastCompany.

The main YouTube app uses InnerTube, as do other YouTube clients (e.g. YouTube Kids). Every protobuf message requires a field usually under the key path "context.client.clientName", which is an enum. 

This project was written for research purposes. InnerTube was a previously undocumented service. 

### Additional Components

[DisPlayers-Audio-Visualizers](https://github.com/agilie/DisPlayers-Audio-Visualizers) is used for an audio visualization view at the top of the app.

[protobuf](https://github.com/protocolbuffers/protobuf) was downloaded at the [3.5.1 Release Tag](https://github.com/protocolbuffers/protobuf/releases/tag/v3.5.1) to best match the client I was reverse engineering. 

### LMPrivateGoogleAccessToken

This macro needs to be defined in `LMPrivateGoogleAccessToken.h` as directed in [LMAccessTokenManager.m](music/Services/LMAccessTokenManager.m).

To find the value, open Keychain Access.app on macOS. Enter "com.apple.account.Google.oath-refresh-token" in the search bar. You may have multiple Google Accounts. 
Select each cell, and a preview will be provided at the top of the app. Right click the cell of the account you'd like to use. Select "Copy Password to Clipboard".

> **Note**:  This is a workaround for a non-priority feature: logging into a Google Account in the app.
