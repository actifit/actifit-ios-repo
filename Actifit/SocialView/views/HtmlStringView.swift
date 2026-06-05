//
//  HtmlStringView.swift
//  Actifit
//
//  Created by Ali Jaber on 11/10/2024.
//

import WebKit
import SwiftUI

import SwiftUI
import WebKit

struct HTMLMarkdownView: View {
    let content: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let attributedText = try? AttributedString(markdown: content) {
                    // Render text with basic markdown styling
                    Text(attributedText)
                        .padding()
                }

                if containsComplexHTML(content: content) {
                    // For complex HTML, we use a WebView
                    HTMLView(htmlContent: content)
                        .frame(height: 300)
                }
            }
            .padding()
        }
    }

    // A function to determine if the content contains complex HTML
    func containsComplexHTML(content: String) -> Bool {
        let htmlTags = ["<img", "<video", "<table", "<iframe", "<div", "<span"]
        return htmlTags.contains(where: content.contains)
    }
}

struct HTMLView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

struct HTMLMarkdownView_Previews: PreviewProvider {
    static var previews: some View {
        HTMLMarkdownView(content:"#### Actifit Curation Report 203💪🏃🏅\n\nWe are excited to present another round of our curation effort.\nReports included are selected by the Actifit team. Curated reports received extra upvote rewards by OCD team. \n\nReports were selected based on various factors, including content quality, originality, and the information within. They can be a fun read, an inspiration or a motivation for all of us and of course, to earn more rewards, but it also helps to make more friends :)\nVia this initiative, we are trying to accomplish the below:\n- Increase the rewards to our existing high-quality content writers(in addition to our existing quality content focused report rewards and weekly staff picks selections)\n- Bring in new fitness bloggers to actifit and hive with quality focus\n- Motivate existing users to write better quality content and compete over rewards.\n\n---\n\n## Extra Rewarded Reports\n\n\n### [Curated Report 1](https://actifit.io/@browery/actifit-browery-20241009t034154776z) by @browery\n\n![](https://images.hive.blog/0x0/https://files.peakd.com/file/peakd-hive/browery/243BcQFqMjy5YaM4miDuC9GD7MyozQJDWSYwWPhtRvCf8d5DN8FUGjFjnDBWzLcpHRaAg.png)\n\nNew challenge for our actifitter!\n\n### [Curated Report 2](https://actifit.io/@dioskr-swc/actifit-dioskr-swc-20241009t034305790z) by @dioskr-swc\n\n![](https://images.hive.blog/0x0/https://files.peakd.com/file/peakd-hive/dioskr-swc/23tbK736pEgjrMKFaaucaMQ1QA5z32eezwGnvVYRsL6e8YiVKF8PgNPWGNxZFzT26byw9.gif)\n\nCallisthenics training and a short walking\n\n### [Curated Report 3](https://actifit.io/@asia-pl/actifit-asia-pl-20241009t103403037z) by @asia-pl\n\n![](https://images.ecency.com/DQmcByzREib5CqpuQAHgMXtb5dPrgC3Cy7crpB54vexMYsr/1728469297708.jpg)\n\nMagic forest walk\n\n### [Curated Report 4](https://actifit.io/@carrinm/actifit-carrinm-20241009t111050154z) by @carrinm\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/e3bf5b9f-68ac-4546-812a-467ec315dd93)\n\n\nKangaroo Valley road trip and Loop around Shoalhaven Heads by bike\n\n### [Curated Report 5](https://actifit.io/@industriousliv/actifit-industriousliv-20241009t002351201z) by @industriousliv\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/344907AF-820D-47C0-B59C-6B79BDCA2B83638640297218512000)\n\nChilly day\n\n### [Curated Report 6](https://actifit.io/@dailyspam/actifit-dailyspam-20241009t081622263z) by @dailyspam\n\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/3a961de0-7037-4fef-9d70-ceb470f24c30)\n\nSardegna trip 2024\n\n### [Curated Report 7](https://actifit.io/@havandris/actifit-havandris-20241009t041913516z) by @havandris\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/7226C232-8AFC-47B0-A96B-56617D28C4D4638640429858653312)\n\nMy Havana’s photo walking Tour \n\n### [Curated Report 8](https://actifit.io/@jayna/actifit-jayna-20241009t041423015z) by @jayna\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/E7918C20-F40D-4042-BB44-98618DDDCB95638640422155905152)\n\nTrail walk in some fall color\n\n### [Curated Report 9](https://actifit.io/@cristofercj-sw/actifit-cristofercj-sw-20241009t185450304z) by @cristofercj-sw\n\n![](https://images.hive.blog/DQmUiHk2MGenWAJhpNi45ajJY28VnWzJPeFdJNhe93K2Q5j/WhatsApp%20Image%202024-10-09%20at%202.26.05%20PM.jpeg)\n\nExercising\n\n### [Curated Report 10](https://actifit.io/@twicejoy/actifit-twicejoy-20241009t184713226z) by @twicejoy\n\n![](https://images.hive.blog/0x0/https://files.peakd.com/file/peakd-hive/twicejoy/23wX5e2WF3AdT3YQig571z91eoCcqeVzMT3yKYMi2baYKmbYNVruLzicJt3GkeXKHRJX8.jpg)\n\nA Sunny And Rainy Wednesday And Another Great Memory\n\n### [Curated Report 11](https://actifit.io/@terganftp/actifit-terganftp-20241009t223143613z) by @terganftp\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/c0855628-db7d-44e2-adb3-2d6b8601427d)\n\nAnother early day\n\n### [Curated Report 12](https://actifit.io/@jmis101/actifit-jmis101-20241010t053419201z) by @jmis101\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/510fc646-edb6-4fde-8e4e-4379fa41e209)\n\nNew Day, New Report!\n\n\n### [Curated Report 13](https://actifit.io/@itz.inno/actifit-itz-inno-20241010t104322541z) by @itz.inno\n\n![](https://images.hive.blog/0x0/https://files.peakd.com/file/peakd-hive/itz.inno/23uFK2P3gJ7R3go9JKUTFBnQihDQmb8u2nSqvDeimTo1WeaVBoFtxrByB3Ssc4ZGqwRj3.jpg)\n\nreturn of the nightwalker\n\n### [Curated Report 14](https://actifit.io/@djbravo/actifit-djbravo-20241010t160813462z) by @djbravo\n\n![](https://images.ecency.com/DQmTAjJQY2BVUAbMs3FXYDXsyxarnQQEwrA68CbqNVM39bt/img_20241010_163301.jpg)\n\nNursery Visit \n\n### [Curated Report 15](https://actifit.io/vinzie1/actifit-vinzie1-20241010t155357654z) by @vinzie1\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/8e80b3b8-dd04-476c-9c67-c76e34171f5e)\n\nWhat happened in the day\n\n### [Curated Report 16](https://actifit.io/@sw-kleymer/actifit-sw-kleymer-20241010t183112900z) by @sw-kleymer\n\n![](https://images.hive.blog/0x0/https://usermedia.actifit.io/15aa434c-9d46-48b1-9748-0bfa2b32e2f3)\n\nNeighborhood biking\n\n## Runners up (did not get the extra upvote).\nBelow are some additional reports which caught our attention but unfortunately not did not make it for the extra OCD vote. \nWe still want to highlight you guys, and better luck next time for some extra vote!\n\n### [Curated Report 17](https://actifit.io/@ninaeatshere/actifit-ninaeatshere-20241009t182346898z) by @ninaeatshere\n\n![](https://usermedia.actifit.io/D9DCB68D-D042-45C3-80E3-739DF4AE1581638640735517426688)\n\nAutumn here, Pilares there...\n\n\n_Special thanks to @priyanarc & @katerinaramm for helping with the curation, and to @katerinaramm & @mcfarhat for helping with the report compilation._\n\n----\n\n*Congratulations and thank you to all of you guys, keep up the great work!*\n\n*If you would like to get your report picked then keep posting authentic quality content in your actifit report!*\n\n----\n\n##### Some tips for writing a good Actifit report.\n\nWriting a nice and beautiful Actifit report is not a daunting task. Talking about your daily activity in a presentable manner can get you to the top list.\n\nTry to make your report readable and understandable.\nThe arrangement of the images also makes the content look attractive. Goes without saying, target using original high-quality images that you own. Using images from other sources is not advisable unless properly attributed and care is taken not to abuse any copyrights.\n\nPlagiarism is a big NO-NO. In case we find plagiarized content, your account risks getting banned. Please take a look at our [Actifit Etiquette](https://actifit.io/@katerinaramm/actifit-etiquette-content-posting-guidelines) for further details.\nTill next week's staff picks!\n\n\n---\n\n<center><b><i>Did you stock up on your gadgets yet? Head over to [Actifit Market NOW](https://actifit.io/market) to WIN!</i></b></center>\n\n#### Actifit Growth & Development Plans 2024 - Vote For Our DHF Proposal!\n\nOur 2023 review and new proposal for 2024 is out! Support our work with your vote: \n    - [Vote on Peakd](https://peakd.com/me/proposals/292)\n    - [Vote on Ecency](https://ecency.com/proposals/292)\n    - [Vote via Hive Wallet](https://wallet.hive.blog/proposals)\n    - [Vote via Hivesigner](https://hivesigner.com/sign/update_proposal_votes?proposal_ids=%5B%22292%22%5D&amp;approve=true)\n\n#### Actifit supports cross-chain decentralization. Support our efforts below:\n* Support our witness @actifit on Hive, vote for us or set us as proxy on [actifit profile](https://actifit.io/actifit), via [peakd](https://peakd.com/witnesses), or [hive blog](https://wallet.hive.blog/~witnesses).\n* Support our witness @actifit-he on Hive-engine, vote for us on [Tribaldex](https://tribaldex.com/witnesses).\n* Support our witness @actifit on Blurt, vote for us or set us as proxy on [Blurt Witness Page](https://blurtwallet.com/~witnesses).\n* Support our block producer actifittelos on Telos, vote for us [here](https://eosauthority.com/vote/producers?network=telos).\n\n@actifit team ")
    }
}
