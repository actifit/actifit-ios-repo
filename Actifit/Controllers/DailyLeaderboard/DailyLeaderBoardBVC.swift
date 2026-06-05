//
//  DailyLeaderBoardBVC.swift
//  Actifit
//
//  Created by Hitender kumar on 16/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit

class DailyLeaderBoardBVC: UIViewController {
    let refreshControl = UIRefreshControl()
    let viewModel = DailyLeaderboardViewModel()
    @IBOutlet weak var backBtn : UIButton!
    @IBOutlet weak var dailyLeaderboardTableView : UITableView!
    var dailyTopActifitters = "Daily Top Actifitters"
    
    lazy var leaderboardArray = {
        return [NSDictionary]()
    }()
    
    //MARK: VIEW LIFE CYCLE
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dailyLeaderboardTableView.tableFooterView = UIView()
        self.setBinding()
        setupInitials()
    }
    
    func setupInitials() {
        dailyTopActifitters    = "activity_leaderboard_title".localized()
        dailyLeaderboardTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        refreshControl.tintColor = .gray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
    }

    @objc func pullToRefresh(_ sender: Any) {
        Task {
            await viewModel.fetchDailyLeaderboard()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.refreshControl.endRefreshing()
        }
    }

    //MARK: INTERFACE BUILDER ACTIONS
    
    @IBAction func backBtnAction(_ sender : UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func postDetailsAction(_ sender : UIButton) {
        print(sender.tag)
        let obj = viewModel.leaderboardArray[sender.tag]
        let postURL = "https://actifit.io" + obj.url
        if let URL = URL(string: postURL) {
            UIApplication.shared.open(URL)
        }
    }

    func setBinding() {
        viewModel.loaderPublisher.sink { showLoader in
                ActifitLoader.hide()
        }.store(in: &viewModel.cancellable)
        viewModel.refreshPublisher.sink { _ in
            self.dailyLeaderboardTableView.reloadData()
        }.store(in: &viewModel.cancellable)
    }
}

extension DailyLeaderBoardBVC : UITableViewDataSource, UITableViewDelegate {
    
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.leaderboardArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : DailyLeaderboardTableCell = tableView.dequeueReusableCell(withIdentifier: "DailyLeaderboardTableCell", for: indexPath) as! DailyLeaderboardTableCell
        let leaderObject = viewModel.leaderboardArray[indexPath.row]  
        
        URLSession.shared.dataTask( with: NSURL(string:leaderObject.userProfilePic)! as URL, completionHandler: {
            (data, response, error) -> Void in
            DispatchQueue.main.async {
                if let data = data {
                     cell.leaderboardImage.image = UIImage(data: data)
                }
            }
        }).resume()
        
        cell.leaderboardRank.text = "\(leaderObject.leaderRank)"
        cell.leaderboardName.text = leaderObject.author
        cell.leaderboardCount.text = "\(leaderObject.activityCount.first ?? "")"
        cell.leaderboardImage.layer.cornerRadius = 16
        cell.leaderboardImage.clipsToBounds =  true
        cell.btnDetails.tag = indexPath.row
        cell.btnDetails.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.form.rawValue, size: 20), for: .normal)
        cell.btnDetails.layer.cornerRadius = 5
        cell.btnDetails.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

}

