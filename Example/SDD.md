# Software Design Document

## Project

### Adding folders
Add the folder outside xcode and then import it into the project. Make shure to mark the create group radio.

### Strucutre of the project

```
Source
    +-SDD.md
    +-REDAME.md
    +-fastlane (folder containing fastlane)
    +-Project
    |   +-Application
    |   +-Scenes
    |   |   +-ItemList
    |   |   |   +-Controllers
    |   |   |   |   +-ItemListViewController.swift
    |   |   |   |   +-ItemListDataController.swift
    |   |   |   |
    |   |   |   +-Models
    |   |   |   |   +-ItemListViewModel.swift
    |   |   |   |
    |   |   |   +-Views
    |   |   |       +-ItemListCell.swift
    |   |   |       +-ItemListCell.xib
    |   |   |
    |   |   +-ItemDetail
    |   |   |   +-Controllers
    |   |   |       +-ItemDetailViewController.swift
    |   |   |
    |   |   +-Shared
    |   |       +-Models
    |   |           +-Item.swift 
    |   |
    |   +-Network Layers ()
    |       +-Helpers (managers, extentions, factories etc...) 
    |       +-Resources (Here goes assets, images, fonts anything that isn't code. exept for xib and storyboards)
    |       +-Storyboards (Here goes the storyboards, no xib's here. they should be located next to  it's owoner)
    |
    +-Dependencies
    +-Tests
        +-UI
        +-Unit
```

####Tests
* tesfiles in the same structure as the resembling file
* no empty folder
