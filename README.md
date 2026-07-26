# Actifit iOS Version
Actifit: It Pays to be Fit!


Actifit tracks and rewards your activity with Actifit's AFIT tokens, but also HIVE, SPORTS and other token rewards.

##### Earn Tokens As Simple As One Two Three
1. Download the Actifit mobile app [Google Play](https://links.actifit.io/android) | [App Store](https://links.actifit.io/ios)
2. Go for a jog, walk your dog, maw your lawn, go to the gym, move around your office,... with an aim to reach a minimum of 5,000 activity count.
3. Post via app, and get rewarded!


##### Actifit (AFIT) Tokens Use Cases
AFIT tokens can be exchanged on Actifit Market to signup for fitness or nutrition related consultation sessions, buying ebooks, boosting your rewards via purchasing actifit based booster gadgets, or earning extra HIVE rewards!

You can buy AFIT tokens on [Hive-Engine.com](https://hive-engine.com/?p=market&t=AFIT)

##### Delegate To Earn More Rewards
You can earn more AFIT tokens if you are a HIVE token holder. Delegate Hive Power to Actifit and earn your share of ~14,000 AFIT tokens distributed per day to our delegators, as well as a weekly share of the 5% beneficiary reward of actifit posts

For a more detailed briefing on the project, check out our introductory post: Announcing Actifit: innovative SMT for rewarding fitness activity!
https://actifit.io/actifit/@actifit/announcing-actifit-innovative-smt-for-rewarding-fitness-activity

##### Sign Up For a New Account
[Signup Link](https://actifit.io/signup)
In order to use Actifit, you need an account on the Hive blockchain (as well as an optional account on Blurt blockchain). If you do not have an account, you can sign up for one right now!
You can create your actifit account for as low as 2$, and get following extra benefits:
- Your actifit account, usable across the Hive and Blurt blockchains and all cool relevant dapps available therein.
- A minimum of 100 AFIT tokens as a free reward. The higher you invest (in batches of 5$), the higher the amount rewarded.
- The Hive blockchain require a min amount of RC (which controls how often you can transact). To help with that, we delegate to your new account a minimum value RC to allow you to properly transact and post easily once per day!
- Via posting your daily activity, you are eligible to earn AFIT tokens, HIVE and BLURT upvotes, as well as SPORTS and other tokens, a free source of earning crypto while getting healthy and fit!
- Owning AFIT tokens allows you to earn more rewards for your daily activity, as it increases your User Rank.
[Signup Link](https://actifit.io/signup)


##### Contact us on
[Our Website](https://actifit.io) |
[Our blog](https://actifit.io/actifit/blog) |
[Discord](https://links.actifit.io/discord) |
[Facebook](https://www.facebook.com/Actifit.fitness/) |
[Twitter](https://www.twitter.com/Actifit_fitness) |
[Instagram](https://www.instagram.com/actifit.fitness/) |
[Download on Google Play](https://links.actifit.io/android) | [Download on App Store](https://links.actifit.io/ios)

---

## Building from source

### Requirements
- macOS with **Xcode** (project builds on current Xcode toolchains)
- **CocoaPods** (`sudo gem install cocoapods`)

### Setup
1. **Clone** the repository.

2. **Install pods** (the `Pods/` directory is not checked in):
   ```sh
   pod install
   ```

3. **Create the local secrets file.** Copy the template and fill in your own values:
   ```sh
   cp Actifit/Structs/Secrets.example.swift Actifit/Structs/Secrets.swift
   ```
   Then edit `Actifit/Structs/Secrets.swift` and replace the placeholders:
   - `appCenterSecret` — Microsoft App Center app secret
   - `deepLAuthKey` — DeepL API auth key (feed translation)
   - `imageUploadToken` — Authorization token for `usermedia.actifit.io` image uploads

4. **Add your Firebase config.** Copy the sample and replace it with the real
   `GoogleService-Info.plist` from your Firebase project:
   ```sh
   cp Actifit/GoogleService-Info.sample.plist Actifit/GoogleService-Info.plist
   ```
   (Both `Secrets.swift` and `GoogleService-Info.plist` are gitignored so real
   credentials are never committed.)

5. **Open the workspace** (not the `.xcodeproj`) and build:
   ```sh
   open Actifit.xcworkspace
   ```

### Notes
- Actifit uses a **server-side broadcast** model: the app sends operations to
  Actifit's backend endpoints, which relay them to the Hive blockchain. The app
  does not sign Hive transactions locally.
- Activity tracking on iOS uses **CoreMotion** (`CMPedometer`), with optional
  **HealthKit** and **Fitbit** as data sources.

## Contributing
Issues and pull requests are welcome. Please open an issue to discuss any
significant change before submitting a PR.

## License
Released under the [MIT License](LICENSE).
