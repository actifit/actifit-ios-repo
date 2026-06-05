//
//  TrackingHistoryVC.swift
//  Actifit
//
//  Created by Hitender kumar on 09/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import SafariServices

class TrackingHistoryVC: UIViewController {

    @IBOutlet weak var trackingHistoryTableView : UITableView!
    @IBOutlet weak var backBtn : UIButton!
    @IBOutlet weak var chartViewBtn: UIButton!
    let refreshControl = UIRefreshControl()
    //@IBOutlet weak var activityHistoryLabel: UILabel!
    //  var history = [Activity]()
    //  var activityHistory = "Activity History"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    let viewModel = TrackingHistoryViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.trackingHistoryTableView.tableFooterView = UIView()
        setupInitials()
        setBinding()
    }

    private func setBinding() {
        viewModel.loaderPublisher.sink { showLoader in
            showLoader ? self.showProgressIndicator() : self.hideProgressIndicator()
        }.store(in: &viewModel.cancellables)
        viewModel.refreshPublisher.sink { refresh in
            if refresh {
                self.trackingHistoryTableView.reloadData()
            }
        }.store(in: &viewModel.cancellables)
    }

    func setupInitials() {
        chartViewBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.charBarHeader.rawValue , size: 24), for: .normal)
        chartViewBtn.layer.cornerRadius = 5
        chartViewBtn.clipsToBounds = true
        //activityHistoryLabel.text = "activity_step_history_title".localized()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        refreshControl.tintColor = .gray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        trackingHistoryTableView.refreshControl = refreshControl
    }

    private func openPost(permlink: String) {
        guard let userName = User.current()?.steemit_username else { return }
        let safari = SFSafariViewController(url: URL(string: "https://actifit.io/\(userName)/\(permlink)")!)
        self.present(safari, animated: true)
        // "http://actifit.io/\(viewModel.username)/\(viewModel.activityPostModel?.permlink ?? "")")
    }

    @objc func pullToRefresh(_ sender: Any) {
        Task {
            await viewModel.getUserPosts()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.refreshControl.endRefreshing()
        }
    }


    //MARK: INTERFACE BUILDER ACTIONS
    @IBAction func chartBtnAction(_ sender: Any) {
        let historyChartVC : HistoryChartVC = HistoryChartVC.instantiateWithStoryboard(appStoryboard: .SB_Main) as! HistoryChartVC
        historyChartVC.history = viewModel.history
        self.navigationController?.pushViewController(historyChartVC, animated: true)
    }

    @IBAction func backBtnAction(_ sender : UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func viewDayHistory(_ sender : UIButton) {
        let historyChartVC : DayHistroyVC = DayHistroyVC.instantiateWithStoryboard(appStoryboard: .SB_Main) as! DayHistroyVC
        historyChartVC.history = viewModel.history
        historyChartVC.selectedDate = viewModel.history[sender.tag].date
        self.navigationController?.pushViewController(historyChartVC, animated: true)
    }
}

extension TrackingHistoryVC : UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.historyWithReportStatus.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : ActivityHistoryCell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath) as! ActivityHistoryCell
        cell.viewHistoryDayButton.tag = indexPath.row
        cell.activity =  viewModel.historyWithReportStatus[indexPath.row]
        cell.onReportTap = { [weak self] in
            self?.openPost(permlink: self?.viewModel.historyWithReportStatus[indexPath.row].post?.permlink ?? "")
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.historyWithReportStatus.count - 1 {
            if viewModel.historyWithReportStatus.count > 19 {
                if let lastAuthor = viewModel.historyWithReportStatus.last?.post?.author, let lastPermlink = viewModel.historyWithReportStatus.last?.post?.permlink {
                    Task {
                        await viewModel.getUserPosts(startAuthor:lastAuthor, startPermlink: lastPermlink)
                    }
                }
            }
        }
    }

}
