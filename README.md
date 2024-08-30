# FractionTree
[![Gem Version](https://badge.fury.io/rb/fraction-tree.svg)](https://badge.fury.io/rb/fraction-tree)

A collection of Stern-Brocot based models and methods.

The Stern-Brocot algorithm describes a way of constructing sets of non-negative fractions arranged in a binary tree.

Construction of a SB tree starts by using the fractions 0/1 and 1/0, where 1/0 denotes infinity. Subsequent fractions are derived by the algorithm, (m + m′)/(n + n′), where m/n is the left adjacent fraction and m′/n′ is the right adjacent fraction, and m/n < m′/n′. This sum is called the mediant.

Given m/n = 0/1 and m′/n′ = 1/0, the first mediant sum, is:

0/1 + 1/0 => (0 + 1)/(1 + 0) = 1/1

Fractions constructed in this way, have the following properties:

1. m/n < (m + m′)/(n + n′) < m′/n′
2. m'n - mn' = 1

## Installing

    gem install fraction-tree

## Authors

[Jose Hales-Garcia](mailto:jose@halesgarcia.com)

## License

This project is licensed under the [MIT] License.

## Acknowledgments

* Concrete Mathematics, chapter 4.5
  Ronald Graham, Donald Knuth & Oren Patashnik
* [Introductory reading on the Stern-Brocot tree](https://en.wikipedia.org/wiki/Stern–Brocot_tree)
* [Trees, Teeth, and Time: The mathematics of clock making](https://www.ams.org/publicoutreach/feature-column/fcarc-stern-brocot)
* [Continued Fractions on the Stern-Brocot Tree](https://www.cut-the-knot.org/blue/ContinuedFractions.shtml)
* [The Stern-Brocot tree and Farey sequences](https://cp-algorithms.com/others/stern_brocot_tree_farey_sequences.html)
* [The Wilson zig-zag (quotient sum) algorithm explained](https://anaphoria.com/wilsonintroMOS.html#zig)
* [Erv Wilson's application of the tree to scales](https://anaphoria.com/sctree.pdf)
