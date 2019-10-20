<div class = "black">
<p align="center" >
    <img src="https://user-images.githubusercontent.com/9576678/62970080-81796600-bdc3-11e9-8814-3e0cb806bb1e.png" width="360" alt="InspireIdaho">
</div>

<p align="center">
    <br>
    <a href="LICENSE">
        <img src="http://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="http://img.shields.io/badge/swift-5.0.1-brightgreen.svg" alt="Swift 5.0.1">
    </a>
</p>


# MyProgress app
Hello InspireIdaho folks!  Feel free to clone, build, install this progress tracking app.  Please review open issues in the tab above, and certainly open new issues with bugs or feature requests as discovered!

Once downloaded and built, this app is can simply be run in the Xcode Simulator.  The app connects to a remote service running in a cloud environment managed by InspireIdaho and accessible from your MyProgress app.  For advanced learners, the [myprogress-vapor-api](https://github.com/InspireIdaho/myprogress-vapor-api) service can also be built and run in a local configuration (on Mac or linux) for testing, contributing and/or just kicking the tires! 

## Requirements:

- Xcode 10.3+

## Installation



To download the app project code, open a Terminal (shell) and run the following:

```sh
cd <local project dir>
git clone https://github.com/InspireIdaho/myprogress-ios.git
```
- project repo is downloaded 

```sh
cd myprogress-ios
git submodule update --init
```
- git downloads files for the embedded [Alamofire](https://github.com/Alamofire/Alamofire) submodule 

```sh
open MyProgress.xcodeproj
```
- Xcode opens the project
- confirm the Run scheme (in the top toolbar) is set to `MyProgress` and select a Simulator device
- click the **Run** button to build and launch the app
- once app launches in Simulator, login with the credentials supplied by your team mentor/expert and start checking off each Unit/Lesson in the *App Development with Swift* iBook as you work thru the curriculum!
 


## Slack Channel

Questions, bugs reports, comments, suggestions, and feature ideas are always welcome,  so come [join our Slack channel](http://inspireidaho.slack.com).

## Contributing
Your contribution to further development of this project is welcome!

There should be plenty of guides out there (including on GitHub help - links TBD) to walk you thru detailed steps; but the basic outline is:

* you register a personal GitHub account (if you don't have one already!)
* Fork this repo to your personal account
* clone your repo to your local Mac
* build/code/test locally
* push your local changes to your Forked repo
* then finally initiate a Pull request to this master repo.

## Credits

This app is developed and maintained by [M. Sean Bonner](https://github.com/mseanbonner) with the collaboration of the [InspireIdaho](https://www.inspireidaho.com) community.

## License

MyProgress is released under an MIT license. See [license](LICENSE) for more information.


