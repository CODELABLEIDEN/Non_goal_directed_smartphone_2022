
==============================

[Documentation](docs/_build/html)

Project Organization
------------

    ├── LICENSE
    ├── README.md          <- The top-level README
    ├── requirements.txt   <- The requirements file for reproducing the analysis environment
    ├── get_started.sh     <- bash script to setup the environment
    ├── LICENSE            <- MIT License
    |
    ├── docs               <- All documentation
    │
    ├── src                <- Source code for use in this project.
    │   │
    │   ├── main.m
    │   ├── alignment            <- Files related to data alignment
    |   |   ├── decision_tree         <- Scripts to analyze the results of the model and choose when to trust the predictions
    |   |   ├── features              <- Scripts to generate the features for training
    |   |   ├── predict               <- Scripts to predict the results
    |   |   └── training              <- Scripts to train the model
    │   │
    │   ├── bs_to_tap            <- Files for the bs to tap models
    |   |       ├── features          <- Scripts to generate the features for training
    |   |       ├── predict           <- Scripts to predict the results
    |   |       └── training          <- Scripts to train the model(s)
    │   │
    │   ├── ams_nams            <- Files to identify attributable (ams) and non attributable movements (nams)
    |   |       └── features                    <- Scripts to identify ams and nams
    |   |
    │   ├── EEG_analysis         <- Scripts to analyze the EEG data
    |   |       ├── ERP_ERSP_data_generation <- Scripts to perform ERP and ERSP analysis
    |   |       ├── t_tests_ERP_and_ERSP     <- Scripts to perform LIMO t-tests
    |   |       └── preprocess_EEG           <- Scripts to pre-process EEG data 
    │   │
    │   └── utils                <- General utility functions used throughout


--------
