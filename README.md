# ActiveStorage::Service::TencentCOSService
Active Storage Serivce for [Tencent COS](https://cloud.tencent.com/product/cos)


## Notes
It is important to note that this library is still in early stages and is currently being implemented according to my needs
- only public read bucket is support(HTTP caching purpose)
- direct upload only
- delete variants have not yet been implemented


## Usage
Enable CORS on your bucket(for direct upload)
https://cloud.tencent.com/document/product/436/13318

Add to your Gemfile
```
gem 'activestorage-tencent_cos'
```

Edit `config/storage.yml`
```yaml
tencent:
  service: TencentCOS
  secret_id: your_secret_id
  secret_key: your_secret_key
  app_id: your_app_id
  bucket: your_bucket
  region: ap-guangzhou # https://cloud.tencent.com/document/product/436/6224
  prefix: /folder # prefix save path
  endpoint: https://assets.example.com # your cdn url
  max_age: 3600 # http cache time
```

Edit `config/environments/production.rb`
```ruby
config.active_storage.service = :tencent
```


## Tips
Use cdn url directly
```ruby
<%= image_tag book.cover.service_url %>
```
