# Ghidra

Updating dependencies is done by running:
```
$ ./generate-deps.sh
```

If dependencies are missing, it is likely that some of the manual dependencies that are
listed in `org.ghidra_sre.Ghidra` need to be updated from the [`fetchDependencies.gradle`](https://github.com/NationalSecurityAgency/ghidra/blob/master/gradle/support/fetchDependencies.gradle)
script.

## Resources

- Ghidra AUR package ([aur.archlinux.org](https://aur.archlinux.org/packages/ghidra-git))
