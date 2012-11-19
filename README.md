share.rb
========

port of sharejs server to Ruby ( rack/thin )

<table>
  <tr>
    <td>ShareJS commit</td>
    <td>
      <a href="https://github.com/josephg/ShareJS/compare/7a953a8...master">
        <img src="http://gh-compare.herokuapp.com/repos/josephg/ShareJS/compare/7a953a8...master.png">
      </a>
    </td>
  </tr>

  <tr>
    <td>Build Status</td>
    <td>
      <a href="https://travis-ci.org/collin/share.rb">
        <img src="https://travis-ci.org/collin/share.rb.png">
      </a>
    </td>
  </tr>

  <tr>
    <td>Dependencies</td>
    <td>
      <a href="https://gemnasium.com/collin/share.rb">
        <img src="https://gemnasium.com/collin/share.rb.png">
      </a>
    </td>
  </tr>

  <tr>
    <td>Is it any good?</td>
    <td>
      <a href="https://codeclimate.com/github/collin/share.rb">
        <img src="https://codeclimate.com/badge.png">
      </a>
    </td>
  </tr>
</table>

# Give it a whirl!


## Run this
```sh
git clone https://github.com/collin/share.rb.git
cd share.rb/example
bundle
rails runner "Share::Adapter::ActiveRecord::Document.create_tables"
rails server
```

## Browse to
### Pads:
```
localhost:3000/documents/my-first-pad
```
### Documents:
```
localhost:3000/documents/my-first-document
```




