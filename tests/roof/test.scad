module sketch() {
    polygon(points=[[-5,-1],[-0.15,-1],[0,0],[0.15,-1],[5,-1],
    [5,-0.1],[4,0],[5,0.1],[5,1],[-5,1]]);
}

roof(method = "straight") sketch();
