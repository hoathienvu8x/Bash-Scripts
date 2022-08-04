for (int i = 1; i < argc; i++) {

    if (strcmp(argv[i],"-i")==0) {
        filename = argv[i+1];
        printf("filename: %s",filename);
    } else if (strcmp(argv[i],"-c")==0) {
        convergence = atoi(argv[i + 1]);
        printf("\nconvergence: %d",convergence);
    } else if (strcmp(argv[i],"-a")==0) {
        accuracy = atoi(argv[i + 1]);
        printf("\naccuracy:%d",accuracy);
    } else if (strcmp(argv[i],"-t")==0) {
        targetBitRate = atof(argv[i + 1]);
        printf("\ntargetBitRate:%f",targetBitRate);
    } else if (strcmp(argv[i],"-f")==0) {
        frameRate = atoi(argv[i + 1]);
        printf("\nframeRate:%d",frameRate);
    }

}
