//
//  ViewController.swift
//  Books
//
//  Created by Winston Maragh on 10/17/18.
//  Copyright © 2018 Winston Maragh. All rights reserved.
//

import UIKit
import SkeletonView

final class CategoryVC: UIViewController {
    
    private let categoriesView = CategoriesView()
    private let dataService = BookDataService()

    private var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    private var categories: [NYTBookCategory] = [] {
        didSet {
            reloadCollectionView()
        }
    }

    private var filteredCategories: [NYTBookCategory] = [] {
        didSet {
            reloadCollectionView()
        }
    }
    
    private var booksDict: [String : [NYTBestSellerBook]] = [:]
    
    private var startup: Bool = true
    
    override func viewWillAppear(_ animated: Bool) {
        if startup {
            presentLaunchVideoScreen()
            startup = false
        }
    }
    
    override func loadView() {
        view = categoriesView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupSearchController()
        setupCollectionView()
        makeSkeletonable()
        networkCheck()
    }
    
    private func presentLaunchVideoScreen() {
        let loadingVC = LoadingVC()
        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve
        present(loadingVC, animated: true, completion: nil)
    }

    private func setupNavBar(){
        navigationItem.title = "Book Categories"

        if #available(iOS 11.0, *) {
            navigationItem.searchController = searchController
        } else {
            navigationItem.titleView = searchController.searchBar
        }
        
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupSearchController(){
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.barStyle = .default
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.tintColor = .gray
        searchController.searchBar.showsCancelButton = true
        searchController.searchBar.placeholder = "Search book categories..."
        
        if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textfield.textColor = UIColor.darkGray
            if let backgroundview = textfield.subviews.first {
                backgroundview.backgroundColor = UIColor.white
                backgroundview.layer.cornerRadius = 10;
                backgroundview.clipsToBounds = true;
            }
        }
        
        if ((searchController.searchBar.responds(to: NSSelectorFromString("searchBarStyle")))){
            searchController.searchBar.searchBarStyle = .minimal
        }
        
        searchController.definesPresentationContext = true
    }
    
    private func setupCollectionView() {
        categoriesView.collectionView.delegate = self
        categoriesView.collectionView.dataSource = self
    }
    
    private func reloadCollectionView() {
        DispatchQueue.main.async { [unowned self] in
            self.categoriesView.collectionView.reloadData()
        }
    }
    
    private func makeSkeletonable() {
        view.isSkeletonable = true
        categoriesView.isSkeletonable = true
        categoriesView.collectionView.isSkeletonable = true
        searchController.searchBar.isSkeletonable = true
        navigationController?.navigationBar.isSkeletonable = true
        showOrHideSkeleton()
    }
    
    private func showOrHideSkeleton() {
        categoriesView.collectionView.prepareSkeleton(completion: {[weak self] done in
            guard let weakSelf = self else { return }
            if weakSelf.categories.isEmpty {
                weakSelf.view.showAnimatedSkeleton()
            } else {
                weakSelf.view.hideSkeleton(reloadDataAfter: true)
            }
        })
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredCategories.removeAll()
        filteredCategories = categories.filter({( category : NYTBookCategory) -> Bool in
            return category.displayName.lowercased().contains(searchText.lowercased())
        })
        reloadCollectionView()
    }
    
    private func showAlert (title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func networkCheck() {
        if NetworkAvailable.shared.reachability.connection != .none {
            fetchCategories()
        } else {
            showOfflineVC()
        }
        
        NetworkAvailable.shared.reachability.whenUnreachable = { [unowned self] reachability in
            self.showOfflineVC()
        }
    }
    
    private func fetchCategories() {
        dataService.getBookCategories {[weak self] (networkError, bookCategories) in
            guard let weakSelf = self else { return }
            
            if let bookCategories = bookCategories {
                weakSelf.categories = bookCategories
                weakSelf.showOrHideSkeleton()
            }
        }
    }

    private func showOfflineVC() {
        let offlineVC = OfflineVC()
        offlineVC.modalTransitionStyle = .crossDissolve
        offlineVC.modalPresentationStyle = .overFullScreen
        present(offlineVC, animated: true, completion: nil)
    }

}



extension CategoryVC: SkeletonCollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return searchController.isActive ? filteredCategories.count : categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.cellID, for: indexPath) as! CategoryCell
        let category = searchController.isActive ? filteredCategories[indexPath.item] : categories[indexPath.item]
        cell.configureCell(category: category)
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return CategoryCell.cellID
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdenfierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        skeletonView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.cellID)
        return CategoryCell.cellID
    }
    
    func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }
    
}


extension CategoryVC: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let category = categories[indexPath.item]
        let bestSellerVC = BestSellerVC(category: category)
        self.navigationController?.pushViewController(bestSellerVC, animated: true)
    }
    
}


extension CategoryVC: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 15.0
        layout.minimumInteritemSpacing = 5.0
        layout.sectionInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        let numberOfItemsPerRow: CGFloat = 2.0
        let itemWidth: CGFloat = (collectionView.bounds.width / numberOfItemsPerRow) - 20.0
        let itemHeight: CGFloat = collectionView.bounds.height / 10
        return CGSize(width: itemWidth, height: itemHeight)
    }
}


extension CategoryVC: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
}
