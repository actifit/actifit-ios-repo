//
//  NotificationsViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 25/07/2023.
//

import UIKit
import SafariServices
class NotificationsViewController: UIViewController {
    @IBOutlet weak var backButton: UIButton!
    let refreshControl = UIRefreshControl()

    @IBOutlet weak var tableView: UITableView!
    let notificationModel = NotificationViewModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()

        // Do any additional setup after loading the view.
    }
    
    private func setBinding() {
        notificationModel.loaderStatusPublisher.sink { showLoader in
            self.setLoaderStatus(showLoader: showLoader)
        }.store(in: &notificationModel.cancellables)
        
        notificationModel.notificationsPublisher.receive(on: DispatchQueue.main).sink { dataReceived in
            if dataReceived {
                self.tableView.reloadData()
            }
        }.store(in: &notificationModel.cancellables)
    }
    
    
    @IBAction func onBackTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func setUI() {
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        refreshControl.tintColor = .gray
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        tableView.refreshControl = refreshControl

        backButton.tintColor = UIColor.white
        setLoaderStatus(showLoader: true)
        setBinding()
        tableView.register(UINib(nibName: "NotificationsCell", bundle: nil), forCellReuseIdentifier: "NotificationsCell")
        self.navigationController?.navigationBar.isHidden = true
    }

    @objc func pullToRefresh(_ sender: Any) {
        Task {
            await notificationModel.getNotifications()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.refreshControl.endRefreshing()
        }
    }

    static func create() -> NotificationsViewController {
        let vc = UIStoryboard(name: "Notifications", bundle: nil).instantiateViewController(withIdentifier: "NotificationsViewController") as! NotificationsViewController
        return vc
    }
    
    private func openLink(url: String) {
        if let finalURL = URL(string: url) {
            present(SFSafariViewController(url: finalURL), animated: true)
        }
    }
    
    private func setLoaderStatus(showLoader: Bool) {
        showLoader ? SwiftLoader().sharedInstance.show(animated: true) : SwiftLoader().sharedInstance.hide()
    }
    

}

extension NotificationsViewController: UITableViewDelegate {
    
}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notificationModel.notificationsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationsCell") as? NotificationsCell
        cell?.notificationModel = notificationModel.notificationsList[indexPath.row]
        cell?.onLinkTapped = { [weak self] url in
            self?.openLink(url: url)
        }
        return cell!
    }
    
    
}
