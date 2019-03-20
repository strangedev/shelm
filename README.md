# shelm

"Secure helm"

Convenience script for `helm` which simplifies usage with TLS 
authentication, as described in [this blogpost by Bitnami](https://engineering.bitnami.com/articles/helm-security.html).

## Usage

The baic workflow is:

1. Add an identity (client certificate and key)
2. Use `shelm` instead of `helm` when helming

### Managing Identities

You can manage your identities by using:

```bash
$ shelm identity COMMAND [ARGS...]
```

#### Commands

##### `add CLIENT_CERT CA_CERT`

Adds a new identity. Requires a client key file to be present in the same directory
as the client certificate file. You should have something like this:

```
.
|_ myIdentity.crt
|_ myIdentity.key
|_ issuingAuthority.crt
```

Client cert and key have to have the same base name.

In the example above, the identity will be added as `myIdentity`.

##### `list`

Displays a list of all known identities and shows which one is currently selected.

##### `remove NAME`

Removes an identity.

##### `use NAME`

Marks an identity so that it will be used the next time you invoke `shelm`.

### Helming

Once a identity is configured and selected by the `shelm identity use NAME` command,
`shelm` can by used the same as helm. Just replace `helm` with `shelm`.